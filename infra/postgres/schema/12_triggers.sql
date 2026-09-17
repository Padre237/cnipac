-- =============================================================================
-- CNIPAC — 12 : triggers
-- Sources : SDD V4.0 §12.5 et §12.7 (immuabilité, littérales),
--           SRS V2.0 §11 (règles de gestion appliquées au niveau base).
--
-- Principe : une règle dont la violation serait irréversible est appliquée par
-- la BASE, et non par l'application seule. La couche applicative peut être
-- contournée ; le moteur, non.
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Immuabilité du journal d'audit — SDD §12.7, art. 32 de la Loi 2024/001.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_evenement_audit_chainage
  BEFORE INSERT ON evenement_audit
  FOR EACH ROW EXECUTE FUNCTION chainer_evenement_audit();

CREATE TRIGGER trg_evenement_audit_no_update
  BEFORE UPDATE ON evenement_audit
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_audit();

CREATE TRIGGER trg_evenement_audit_no_delete
  BEFORE DELETE ON evenement_audit
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_audit();

-- Les triggers ci-dessus ne couvrent pas TRUNCATE, qui ne déclenche pas de
-- trigger FOR EACH ROW. Sans cette protection, un seul TRUNCATE effacerait le
-- journal sans laisser de trace.
CREATE TRIGGER trg_evenement_audit_no_truncate
  BEFORE TRUNCATE ON evenement_audit
  FOR EACH STATEMENT EXECUTE FUNCTION rejeter_modification_audit();

-- -----------------------------------------------------------------------------
-- Immuabilité des soumissions Kobo — SDD §12.5, RG-M1-04.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_soumission_kobo_no_update
  BEFORE UPDATE ON soumission_kobo
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_soumission();

CREATE TRIGGER trg_soumission_kobo_no_delete
  BEFORE DELETE ON soumission_kobo
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_soumission();

CREATE TRIGGER trg_soumission_kobo_no_truncate
  BEFORE TRUNCATE ON soumission_kobo
  FOR EACH STATEMENT EXECUTE FUNCTION rejeter_modification_soumission();

-- Le journal d'ingestion est immuable au même titre (SDD §11.3).
CREATE TRIGGER trg_journal_ingestion_no_update
  BEFORE UPDATE ON journal_ingestion
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_soumission();

CREATE TRIGGER trg_journal_ingestion_no_delete
  BEFORE DELETE ON journal_ingestion
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_soumission();

-- L'historique des versions ne se réécrit pas : UC-M4-07 et UC-M4-08 reposent
-- sur son intégrité, et ADR-027 en protège le schéma.
CREATE OR REPLACE FUNCTION rejeter_modification_version()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'version_fiche est un historique : modification et suppression rejetées (ADR-006, UC-M4-07)';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_version_fiche_no_update
  BEFORE UPDATE ON version_fiche
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_version();

CREATE TRIGGER trg_version_fiche_no_delete
  BEFORE DELETE ON version_fiche
  FOR EACH ROW EXECUTE FUNCTION rejeter_modification_version();

-- -----------------------------------------------------------------------------
-- RG-M1-05 — automate des statuts de fiche.
-- « nouvelle > quarantaine > validee > (editee)* > archivee. Aucune transition
--   arrière n'est autorisée sans intervention d'un super-administrateur tracée. »
-- La dérogation passe par le paramètre de session cnipac.transition_forcee,
-- que seul le rôle R-01 peut positionner, et qui laisse une trace au journal.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION controler_transition_statut_fiche()
RETURNS TRIGGER AS $$
DECLARE
  v_autorise BOOLEAN;
  v_forcee   TEXT := current_setting('cnipac.transition_forcee', TRUE);
BEGIN
  IF NEW.statut_fiche = OLD.statut_fiche THEN
    RETURN NEW;
  END IF;

  v_autorise := CASE OLD.statut_fiche
    WHEN 'nouvelle'    THEN NEW.statut_fiche = 'quarantaine'
    WHEN 'quarantaine' THEN NEW.statut_fiche IN ('validee', 'rejetee')
    WHEN 'validee'     THEN NEW.statut_fiche IN ('editee', 'archivee')
    WHEN 'editee'      THEN NEW.statut_fiche IN ('editee', 'archivee')
    WHEN 'rejetee'     THEN FALSE   -- terminal
    WHEN 'archivee'    THEN FALSE   -- terminal : archivage logique, jamais suppression
    ELSE FALSE
  END;

  IF NOT v_autorise THEN
    IF v_forcee = 'on' THEN
      RAISE WARNING 'Transition forcée % -> % sur la fiche % (RG-M1-05 : intervention super-administrateur)',
        OLD.statut_fiche, NEW.statut_fiche, NEW.code_producteur;
    ELSE
      RAISE EXCEPTION
        'Transition de statut interdite : % -> % (RG-M1-05). Fiche %. '
        'Une transition arrière exige une intervention tracée de super-administrateur.',
        OLD.statut_fiche, NEW.statut_fiche, NEW.code_producteur;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_producteur_transition_statut
  BEFORE UPDATE OF statut_fiche ON producteur
  FOR EACH ROW EXECUTE FUNCTION controler_transition_statut_fiche();

-- -----------------------------------------------------------------------------
-- RG-M1-02 — le code producteur n'est JAMAIS modifiable.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION interdire_modification_code_producteur()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code_producteur IS DISTINCT FROM OLD.code_producteur THEN
    RAISE EXCEPTION
      'Le code producteur est immuable (RG-M1-02) : tentative de passage de % à %. '
      'Il fonde la pérennité des URI de l''API publique (FR-M7-04).',
      OLD.code_producteur, NEW.code_producteur;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_producteur_code_immuable
  BEFORE UPDATE OF code_producteur ON producteur
  FOR EACH ROW EXECUTE FUNCTION interdire_modification_code_producteur();

-- -----------------------------------------------------------------------------
-- Cohérence de la hiérarchie administrative.
-- `commune_id` porte l'arrondissement ; region_id et departement_id sont
-- dénormalisés pour le filtrage cartographique. Ils doivent rester cohérents.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION synchroniser_hierarchie_admin()
RETURNS TRIGGER AS $$
DECLARE
  v_dep UUID;
  v_reg UUID;
  v_niveau niveau_unite_admin_enum;
BEGIN
  SELECT niveau, parent_id INTO v_niveau, v_dep
  FROM cnipac.unite_admin WHERE id = NEW.commune_id;

  IF v_niveau IS NULL THEN
    RAISE EXCEPTION 'Unité administrative introuvable : %', NEW.commune_id;
  END IF;
  IF v_niveau NOT IN ('commune', 'arrondissement') THEN
    RAISE EXCEPTION
      'producteur.commune_id doit désigner une commune ou un arrondissement, or le niveau est « % »',
      v_niveau;
  END IF;

  SELECT parent_id INTO v_reg FROM cnipac.unite_admin WHERE id = v_dep;

  NEW.departement_id := v_dep;
  NEW.region_id := v_reg;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_producteur_hierarchie_admin
  BEFORE INSERT OR UPDATE OF commune_id ON producteur
  FOR EACH ROW EXECUTE FUNCTION synchroniser_hierarchie_admin();

COMMENT ON FUNCTION synchroniser_hierarchie_admin IS
  'Déduit région et département depuis l''arrondissement. La dénormalisation '
  'sert le filtrage de la carte (FR-M2-02) ; le trigger garantit qu''elle ne '
  'peut jamais diverger de la hiérarchie de référence.';

-- -----------------------------------------------------------------------------
-- Horodatage de modification sur toutes les tables portant updated_at.
-- -----------------------------------------------------------------------------
DO $$
DECLARE t TEXT;
BEGIN
  FOR t IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables tb
      ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name
    WHERE c.table_schema = 'cnipac'
      AND c.column_name = 'updated_at'
      AND tb.table_type = 'BASE TABLE'
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_touch_updated_at BEFORE UPDATE ON cnipac.%I
       FOR EACH ROW EXECUTE FUNCTION cnipac.touch_updated_at()', t, t);
  END LOOP;
END
$$;

-- -----------------------------------------------------------------------------
-- Recalcul des indices dérivés lorsque leurs sources changent.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rafraichir_score_maturite()
RETURNS TRIGGER AS $$
DECLARE v_prod UUID := COALESCE(NEW.producteur_id, OLD.producteur_id);
BEGIN
  UPDATE cnipac.producteur
     SET score_maturite = cnipac.calculer_score_maturite(v_prod)
   WHERE id = v_prod;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_maturite_rafraichir_score
  AFTER INSERT OR UPDATE OR DELETE ON maturite_archivistique
  FOR EACH ROW EXECUTE FUNCTION rafraichir_score_maturite();

CREATE OR REPLACE FUNCTION rafraichir_indice_risque()
RETURNS TRIGGER AS $$
BEGIN
  NEW.indice_risque := cnipac.calculer_indice_risque(
    NEW.etat_materiel, NEW.risques_environnementaux, NEW.dispositifs_securite);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evaluation_rafraichir_risque
  BEFORE INSERT OR UPDATE OF etat_materiel, risques_environnementaux, dispositifs_securite
  ON evaluation_conservation
  FOR EACH ROW EXECUTE FUNCTION rafraichir_indice_risque();
