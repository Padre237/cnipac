-- =============================================================================
-- CNIPAC — 11 : fonctions stockées
-- Source : SDD V4.0 §12.11. Le SDD limite volontairement le recours aux
-- fonctions stockées « aux opérations dont la performance critique justifie
-- l'exécution au niveau base » : calcul de hachage, génération de séquence,
-- triggers d'immuabilité. La logique métier reste en TypeScript.
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Hachage d'un événement d'audit — SDD §12.7, transcription LITTÉRALE.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_hash_evenement(
  p_id UUID, p_sequence BIGINT, p_horodatage TIMESTAMP WITH TIME ZONE,
  p_utilisateur_id UUID, p_action TEXT, p_ressource_type TEXT,
  p_ressource_id UUID, p_payload_avant JSONB, p_payload_apres JSONB,
  p_prev_hash CHAR(64)
) RETURNS CHAR(64) AS $$
BEGIN
  RETURN encode(
    digest(
      coalesce(p_id::text,'') || '|' || coalesce(p_sequence::text,'') || '|' ||
      coalesce(p_horodatage::text,'') || '|' || coalesce(p_utilisateur_id::text,'') || '|' ||
      coalesce(p_action,'') || '|' || coalesce(p_ressource_type,'') || '|' ||
      coalesce(p_ressource_id::text,'') || '|' || coalesce(p_payload_avant::text,'') || '|' ||
      coalesce(p_payload_apres::text,'') || '|' || coalesce(p_prev_hash,''),
      'sha256'
    ),
    'hex'
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculer_hash_evenement IS
  'SDD §12.7. Concatène les champs signifiants de l''événement et le hachage du '
  'précédent, puis applique SHA-256. IMMUTABLE : le même tuple donne toujours le '
  'même hachage, condition de la vérifiabilité a posteriori.';

-- -----------------------------------------------------------------------------
-- Triggers d'immuabilité — SDD §12.5 et §12.7, transcription LITTÉRALE.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rejeter_modification_audit()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'evenement_audit INSERT-ONLY : opération rejetée (cf. ADR-009 et NFR-C3-05)';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION rejeter_modification_soumission()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Soumission Kobo IMMUABLE : modification rejetée (cf. RG-M1-04 et ADR §10.4.3)';
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- Chaînage du journal d'audit.
-- Le SDD fournit la fonction de hachage mais pas le mécanisme qui l'applique.
-- Le verrou consultatif transactionnel est indispensable : sans lui, deux
-- insertions concurrentes liraient le même prev_hash et produiraient une
-- bifurcation de la chaîne, indétectable ensuite.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION chainer_evenement_audit()
RETURNS TRIGGER AS $$
DECLARE
  v_prev_hash CHAR(64);
BEGIN
  -- Sérialise les insertions dans le journal pour la durée de la transaction.
  PERFORM pg_advisory_xact_lock(hashtext('cnipac.evenement_audit'));

  SELECT hash INTO v_prev_hash
  FROM cnipac.evenement_audit
  ORDER BY sequence DESC
  LIMIT 1;

  NEW.prev_hash := v_prev_hash;
  NEW.hash := cnipac.calculer_hash_evenement(
    NEW.id, NEW.sequence, NEW.horodatage, NEW.utilisateur_id, NEW.action,
    NEW.ressource_type, NEW.ressource_id, NEW.payload_avant, NEW.payload_apres,
    v_prev_hash
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION chainer_evenement_audit IS
  'Calcule prev_hash et hash à l''insertion. Le verrou consultatif empêche deux '
  'transactions concurrentes de chaîner sur le même prédécesseur — défaut qui '
  'produirait une chaîne bifurquée, donc invérifiable.';

-- -----------------------------------------------------------------------------
-- Vérification intégrale de la chaîne (job mensuel — SDD §11.5).
-- Consigne son résultat dans verification_chaine_audit.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION verifier_chaine_audit(p_declencheur VARCHAR DEFAULT 'job_mensuel')
RETURNS TABLE (intacte BOOLEAN, nb_evenements BIGINT, premiere_rupture BIGINT) AS $$
DECLARE
  v_debut       TIMESTAMP := clock_timestamp();
  v_prev_hash   CHAR(64) := NULL;
  v_rupture     BIGINT := NULL;
  v_nb          BIGINT := 0;
  v_seq_min     BIGINT := 0;
  v_seq_max     BIGINT := 0;
  r             RECORD;
BEGIN
  FOR r IN
    SELECT id, sequence, horodatage, utilisateur_id, action, ressource_type,
           ressource_id, payload_avant, payload_apres, prev_hash, hash
    FROM cnipac.evenement_audit
    ORDER BY sequence ASC
  LOOP
    v_nb := v_nb + 1;
    IF v_seq_min = 0 THEN v_seq_min := r.sequence; END IF;
    v_seq_max := r.sequence;

    -- Le chaînage doit pointer sur le hachage de l'enregistrement précédent.
    IF r.prev_hash IS DISTINCT FROM v_prev_hash THEN
      v_rupture := r.sequence;
      EXIT;
    END IF;

    -- Le hachage stocké doit correspondre au contenu de l'enregistrement.
    IF r.hash <> cnipac.calculer_hash_evenement(
         r.id, r.sequence, r.horodatage, r.utilisateur_id, r.action,
         r.ressource_type, r.ressource_id, r.payload_avant, r.payload_apres, r.prev_hash
       ) THEN
      v_rupture := r.sequence;
      EXIT;
    END IF;

    v_prev_hash := r.hash;
  END LOOP;

  INSERT INTO cnipac.verification_chaine_audit(
    sequence_debut, sequence_fin, nb_evenements, chaine_intacte,
    premiere_rupture_seq, duree_ms, declenche_par
  ) VALUES (
    v_seq_min, v_seq_max, v_nb, v_rupture IS NULL, v_rupture,
    EXTRACT(MILLISECONDS FROM clock_timestamp() - v_debut)::INTEGER, p_declencheur
  );

  RETURN QUERY SELECT v_rupture IS NULL, v_nb, v_rupture;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- Indice de maturité archivistique — RG-M3-01, pondération de l'annexe F.
-- SDD §12.11 : en base pour la performance, appelé par les vues matérialisées M3.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_score_maturite(p_producteur_id UUID)
RETURNS SMALLINT AS $$
DECLARE
  v_score NUMERIC := 0;
  m       RECORD;
  v_a_archiviste BOOLEAN := FALSE;
  v_locaux_dedies BOOLEAN := FALSE;
BEGIN
  SELECT * INTO m FROM cnipac.maturite_archivistique WHERE producteur_id = p_producteur_id;
  IF NOT FOUND THEN
    RETURN NULL;   -- section VI non renseignée : pas de score, et non un zéro
  END IF;

  -- Personnel formé : déclaré par l'archiviste, ou déduit de la présence
  -- d'archivistes au sein du personnel du centre (Kobo III.2).
  SELECT EXISTS (
    SELECT 1 FROM cnipac.centre_personnel cp
    JOIN cnipac.centre_prearchivage c ON c.id = cp.centre_id
    WHERE c.producteur_id = p_producteur_id
      AND cp.type_personnel IN ('arch_ass', 'arch_non_ass')
      AND coalesce(cp.effectif, 0) > 0
  ) INTO v_a_archiviste;

  -- Locaux adaptés : déclaré, ou déduit d'un entrepôt dédié aux archives (III.4).
  SELECT EXISTS (
    SELECT 1 FROM cnipac.centre_prearchivage
    WHERE producteur_id = p_producteur_id AND type_batiment = 'entrepot_archives'
  ) INTO v_locaux_dedies;

  -- Pondération RG-M3-01 (annexe F). La somme des poids vaut exactement 1.
  IF coalesce(m.service_archives_dedie, FALSE)                 THEN v_score := v_score + 0.25; END IF;
  IF coalesce(m.personnel_forme, v_a_archiviste)               THEN v_score := v_score + 0.15; END IF;
  IF coalesce(m.locaux_adaptes, v_locaux_dedies)               THEN v_score := v_score + 0.20; END IF;
  IF 'plan_classement' = ANY(m.outils_gestion)                 THEN v_score := v_score + 0.20; END IF;
  IF 'calendrier_conservation' = ANY(m.outils_gestion)         THEN v_score := v_score + 0.10; END IF;
  IF array_length(m.instruments_recherche, 1) IS NOT NULL
     AND NOT (m.instruments_recherche = ARRAY['aucun']::cnipac.instrument_recherche_enum[])
                                                               THEN v_score := v_score + 0.10; END IF;

  RETURN round(v_score * 100)::SMALLINT;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION calculer_score_maturite IS
  'RG-M3-01, annexe F : service d''archives 25 %, personnel formé 15 %, locaux '
  '20 %, plan de classement 20 %, calendrier de conservation 10 %, instruments '
  'de recherche 10 %. Retourne NULL — et non 0 — lorsque la section VI n''est pas '
  'renseignée : une donnée absente n''est pas une maturité nulle.';

-- -----------------------------------------------------------------------------
-- Indice de risque de conservation (FR-M3-08, ciblage des inspections).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_indice_risque(
  p_etat        etat_materiel_enum[],
  p_risques     risque_environnemental_enum[],
  p_dispositifs dispositif_securite_enum[]
) RETURNS SMALLINT AS $$
DECLARE
  v_score NUMERIC := 0;
BEGIN
  -- Dégradations constatées : 10 points par type, plafonné à 40.
  -- « Bon état général » est retiré : ce n'est pas une dégradation.
  v_score := v_score + LEAST(40, 10 * coalesce(
    array_length(array_remove(coalesce(p_etat, '{}'), 'bon_etat'), 1), 0));

  -- Risques environnementaux : 12 points par risque, plafonné à 36.
  v_score := v_score + LEAST(36, 12 * coalesce(array_length(p_risques, 1), 0));

  -- Absence totale de dispositif de sécurité : 24 points.
  IF p_dispositifs IS NULL
     OR array_length(p_dispositifs, 1) IS NULL
     OR 'aucun' = ANY(p_dispositifs) THEN
    v_score := v_score + 24;
  END IF;

  RETURN LEAST(100, round(v_score))::SMALLINT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculer_indice_risque(etat_materiel_enum[], risque_environnemental_enum[], dispositif_securite_enum[]) IS
  'FR-M3-08 : indice de risque de conservation sur 100, pour le ciblage des '
  'inspections archivistiques (art. 31-34 Loi 2024/001). Fonction PURE sur les '
  'valeurs, afin d''être utilisable depuis un trigger BEFORE INSERT.';

-- Variante par identifiant, pour les recalculs en lot et les vues M3.
CREATE OR REPLACE FUNCTION calculer_indice_risque(p_producteur_id UUID)
RETURNS SMALLINT AS $$
DECLARE e RECORD;
BEGIN
  SELECT * INTO e FROM cnipac.evaluation_conservation WHERE producteur_id = p_producteur_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN cnipac.calculer_indice_risque(e.etat_materiel, e.risques_environnementaux, e.dispositifs_securite);
END;
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------------------------
-- Génération du code producteur — SDD §12.11 et §13.3.2.
-- Format CMR-<RÉSEAU>-<MIN>-<STRUCT>-<SEQ>, immuable à vie (RG-M1-02).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generer_code_producteur(
  p_reseau_id UUID, p_ministere_id UUID, p_sigle_structure VARCHAR
) RETURNS VARCHAR(50) AS $$
DECLARE
  v_reseau    VARCHAR(20);
  v_ministere VARCHAR(20);
  v_struct    VARCHAR(20);
  v_seq       INTEGER;
BEGIN
  SELECT code  INTO v_reseau    FROM cnipac.reseau_archivistique WHERE id = p_reseau_id;
  SELECT sigle INTO v_ministere FROM cnipac.ministere            WHERE id = p_ministere_id;

  IF v_reseau IS NULL THEN
    RAISE EXCEPTION 'Réseau archivistique introuvable : %', p_reseau_id;
  END IF;
  IF v_ministere IS NULL THEN
    RAISE EXCEPTION 'Ministère introuvable : %', p_ministere_id;
  END IF;

  -- Normalisation : majuscules, accents retirés, caractères non alphanumériques
  -- supprimés — le code doit rester utilisable dans une URI (FR-M7-04).
  v_struct := upper(regexp_replace(unaccent(coalesce(p_sigle_structure, 'STRUCT')), '[^A-Za-z0-9]', '', 'g'));
  IF v_struct = '' THEN v_struct := 'STRUCT'; END IF;
  v_struct := left(v_struct, 12);

  v_reseau    := upper(regexp_replace(unaccent(v_reseau),    '[^A-Za-z0-9]', '', 'g'));
  v_ministere := upper(regexp_replace(unaccent(v_ministere), '[^A-Za-z0-9]', '', 'g'));

  -- Incrément atomique : la ligne de compteur est verrouillée par l'UPDATE,
  -- ce qui rend la génération sûre en concurrence (SDD §13.3.2).
  INSERT INTO cnipac.compteur_code_producteur (reseau_code, ministere_sigle, dernier_numero)
  VALUES (v_reseau, v_ministere, 1)
  ON CONFLICT (reseau_code, ministere_sigle)
  DO UPDATE SET dernier_numero = cnipac.compteur_code_producteur.dernier_numero + 1,
                updated_at = NOW()
  RETURNING dernier_numero INTO v_seq;

  RETURN format('CMR-%s-%s-%s-%s', v_reseau, v_ministere, v_struct, lpad(v_seq::text, 4, '0'));
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generer_code_producteur IS
  'FR-M1-06 et RG-M1-02 : code généré automatiquement à la validation, jamais '
  'modifiable ensuite. Il fonde la pérennité des URI de l''API publique (FR-M7-04).';

-- -----------------------------------------------------------------------------
-- Clé de déduplication — RG-M1-03 : triplet (sigle, ministère, commune).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cle_deduplication(
  p_sigle VARCHAR, p_ministere_id UUID, p_commune_id UUID
) RETURNS VARCHAR AS $$
BEGIN
  RETURN upper(regexp_replace(unaccent(coalesce(p_sigle, '')), '\s+', ' ', 'g'))
      || '|' || coalesce(p_ministere_id::text, '')
      || '|' || coalesce(p_commune_id::text, '');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION cle_deduplication IS
  'RG-M1-03 : deux soumissions partageant ce triplet sont des doublons '
  'potentiels. La règle ne bloque pas les services déconcentrés, qui partagent '
  'légitimement un sigle dans des communes différentes.';

-- -----------------------------------------------------------------------------
-- Correspondance nomenclature terrain -> nomenclature SRS.
-- Le formulaire Kobo (I.2) propose 5 types d'organisation ; le SRS §12.10 en
-- définit 7. La correspondance est explicite plutôt qu'implicite.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mapper_type_organisation(p_kobo type_organisation_enum)
RETURNS type_entite_enum AS $$
BEGIN
  RETURN CASE p_kobo
    WHEN 'ministere' THEN 'ministere_central'
    WHEN 'ctd'       THEN 'ctd'
    WHEN 'ep'        THEN 'etablissement_public'
    WHEN 'rattache'  THEN 'service_deconcentre'
    WHEN 'privee'    THEN 'autre'
    ELSE 'autre'
  END::cnipac.type_entite_enum;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION mapper_type_organisation IS
  'Kobo I.2 propose « Service déconcentré (CTD) » sous le code `ctd`, ce qui '
  'confond deux notions distinctes du SRS §12.10 : les CTD (collectivités '
  'territoriales décentralisées) et les services déconcentrés de l''État. '
  'La correspondance retenue privilégie le libellé du code. Point à arbitrer '
  'avec les ANC — voir docs/ANOMALIES-DOCUMENTAIRES.md.';

-- -----------------------------------------------------------------------------
-- Horodatage de modification, partagé par toutes les tables à updated_at.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
