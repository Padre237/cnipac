-- =============================================================================
-- CNIPAC — 05 : sections métier III à VIII
--
-- Transcription du formulaire KoboToolbox docs/aw2T2qSbuxp3GQdm3wdySZ.xlsx,
-- croisée avec le dictionnaire de données du SRS V2.0 §12.4 à §12.9.
-- Chaque colonne porte en commentaire le nom EXACT de la question Kobo dont
-- elle provient (colonne `name` de la feuille `survey`).
--
-- PRINCIPE DE MODÉLISATION
-- Le formulaire attache une QUANTITÉ à certains choix multiples : un support
-- sélectionné déclenche la saisie de son volume, un type de personnel celle de
-- son effectif. Ces deux listes sont donc des tables de jonction porteuses
-- d'attributs, et non de simples tableaux. Les choix multiples sans quantité
-- sont stockés en tableaux d'ENUM, indexés en GIN.
-- =============================================================================
SET search_path TO cnipac, public;

-- #############################################################################
-- SECTION III — Centre de préarchivage / Local de conservation principal
-- Kobo : groupe `resp_pers` | SRS §12.4 | Norme ISDIAH 3.4 et 3.5
-- #############################################################################

CREATE TABLE centre_prearchivage (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id   UUID NOT NULL REFERENCES producteur(id) ON DELETE CASCADE,

  -- Le TDR §5 prévoit un affichage cartographique distinct « producteurs
  -- uniquement / centres uniquement / les deux » : le centre porte donc sa
  -- propre géométrie. Kobo `gps_prearch` (II.2).
  geom            geometry(Point, 4326),
  est_principal   BOOLEAN NOT NULL DEFAULT TRUE,
  libelle         VARCHAR(200),

  -- III.1 Responsable — Kobo `poste_resp`, `nom_resp`
  -- DONNÉES NOMINATIVES : jamais exposées par l'API publique (NFR-C4-01).
  responsable_poste   VARCHAR(200),
  responsable_nom     VARCHAR(200),
  responsable_tel     VARCHAR(20),    -- SRS §12.4 III.3
  responsable_email   VARCHAR(100),   -- SRS §12.4 III.4

  -- III.2 Personnel — Kobo `nb_total`
  personnel_total     INTEGER,
  personnel_autres_precision TEXT,    -- Kobo `prec_autres_personnel`

  -- III.3 — Kobo `structure_rattachement`
  structure_rattachement TEXT,

  -- III.4 — Kobo `type_batiment`, `type_batiment_autre`
  type_batiment          type_batiment_enum,
  type_batiment_autre    VARCHAR(200),

  -- III.5 Superficie — Kobo `surf_tot`, `surf_occ`
  surface_totale_m2      NUMERIC(10,2),
  surface_occupee_m2     NUMERIC(10,2),

  -- SRS §12.4 III.7 et III.8 (absents du formulaire, calculables ou à saisir)
  volume_lineaire_ml     NUMERIC(10,2),
  capacite_residuelle_pct SMALLINT,

  created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_centre_geom_in_cameroun
    CHECK (geom IS NULL OR (ST_X(geom) BETWEEN 8.5 AND 16.2 AND ST_Y(geom) BETWEEN 1.6 AND 13.1)),
  CONSTRAINT chk_centre_surfaces_positives
    CHECK (surface_totale_m2 IS NULL OR surface_totale_m2 >= 0),
  -- La surface occupée ne peut excéder la surface totale : incohérence de saisie
  -- fréquente sur le terrain, arrêtée ici plutôt qu'en aval.
  CONSTRAINT chk_centre_surface_occupee_coherente
    CHECK (surface_occupee_m2 IS NULL OR surface_totale_m2 IS NULL
           OR surface_occupee_m2 <= surface_totale_m2),
  CONSTRAINT chk_centre_capacite_residuelle
    CHECK (capacite_residuelle_pct IS NULL OR capacite_residuelle_pct BETWEEN 0 AND 100),
  CONSTRAINT chk_centre_personnel_positif
    CHECK (personnel_total IS NULL OR personnel_total >= 0),
  CONSTRAINT chk_centre_type_batiment_autre
    CHECK (type_batiment IS DISTINCT FROM 'autre' OR type_batiment_autre IS NOT NULL),
  CONSTRAINT chk_centre_responsable_email
    CHECK (responsable_email IS NULL OR responsable_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT chk_centre_responsable_tel
    CHECK (responsable_tel IS NULL OR responsable_tel ~ '^\+237[0-9]{8,12}$')
);

CREATE INDEX idx_centre_prearchivage_producteur ON centre_prearchivage(producteur_id);
CREATE INDEX idx_centre_prearchivage_geom       ON centre_prearchivage USING GIST(geom);
-- Un seul centre principal par producteur.
CREATE UNIQUE INDEX uq_centre_prearchivage_principal
  ON centre_prearchivage(producteur_id) WHERE est_principal;

COMMENT ON TABLE centre_prearchivage IS
  'Local de conservation principal — Section III du formulaire Kobo, SRS §12.4. '
  'Entité distincte du producteur car le TDR §5 exige une couche cartographique '
  'propre aux centres de préarchivage.';
COMMENT ON COLUMN centre_prearchivage.responsable_nom IS
  'DONNÉE NOMINATIVE. Ne doit jamais être exposée par la carte publique ni par '
  'l''API non authentifiée (NFR-C4-01, RG-M2-02, art. 13 Loi 2024/001).';

-- Jonction porteuse d'attribut : Kobo `types_personnel` (choix multiple) et les
-- effectifs conditionnels nb_non_arch / nb_arch_ass / nb_arch_non_ass / nb_info.
CREATE TABLE centre_personnel (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  centre_id      UUID NOT NULL REFERENCES centre_prearchivage(id) ON DELETE CASCADE,
  type_personnel type_personnel_enum NOT NULL,
  effectif       INTEGER,
  precision      TEXT,                -- renseigné pour 'autres'

  CONSTRAINT uq_centre_personnel UNIQUE (centre_id, type_personnel),
  CONSTRAINT chk_centre_personnel_effectif CHECK (effectif IS NULL OR effectif >= 0),
  CONSTRAINT chk_centre_personnel_autres CHECK (type_personnel <> 'autres' OR precision IS NOT NULL)
);

CREATE INDEX idx_centre_personnel_centre ON centre_personnel(centre_id);
CREATE INDEX idx_centre_personnel_type   ON centre_personnel(type_personnel);

COMMENT ON TABLE centre_personnel IS
  'Kobo III.2 : le choix multiple `types_personnel` déclenche la saisie d''un '
  'effectif par type sélectionné. D''où une table de jonction porteuse '
  'd''attribut plutôt qu''un tableau. Alimente l''indice de maturité RG-M3-01 '
  '(critère « personnel formé » : présence d''archivistes assermentés).';

-- #############################################################################
-- SECTION IV — État du patrimoine documentaire
-- Kobo : groupe `patrimoine` | SRS §12.5 | Norme ISAD(G) en perspective
-- #############################################################################

CREATE TABLE patrimoine_documentaire (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id  UUID NOT NULL UNIQUE REFERENCES producteur(id) ON DELETE CASCADE,

  -- IV.1 — Kobo `support_autre`
  support_autre_precision TEXT,

  -- IV.2 Dates extrêmes — Kobo `annee_doc_ancien`, `annee_doc_recent`
  annee_doc_plus_ancien  SMALLINT,
  annee_doc_plus_recent  SMALLINT,

  -- IV.3 Équipement — Kobo `materiau_rayonnage`, `mobilite_rayonnage`, `boites_archives`
  materiau_rayonnage     materiau_rayonnage_enum,
  mobilite_rayonnage     mobilite_rayonnage_enum,
  types_boites           type_boite_enum[] NOT NULL DEFAULT '{}',

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- DQ-04 : la date de début doit être antérieure ou égale à la date de fin.
  CONSTRAINT chk_patrimoine_dates_extremes
    CHECK (annee_doc_plus_ancien IS NULL OR annee_doc_plus_recent IS NULL
           OR annee_doc_plus_ancien <= annee_doc_plus_recent),
  -- Les Archives Nationales conservent des fonds remontant à la période
  -- coloniale ; une année antérieure à 1800 ou postérieure à l'année courante
  -- relève de l'erreur de saisie.
  CONSTRAINT chk_patrimoine_annee_ancien_plausible
    CHECK (annee_doc_plus_ancien IS NULL
           OR annee_doc_plus_ancien BETWEEN 1800 AND EXTRACT(YEAR FROM NOW())::SMALLINT),
  CONSTRAINT chk_patrimoine_annee_recent_plausible
    CHECK (annee_doc_plus_recent IS NULL
           OR annee_doc_plus_recent BETWEEN 1800 AND EXTRACT(YEAR FROM NOW())::SMALLINT)
);

CREATE INDEX idx_patrimoine_producteur ON patrimoine_documentaire(producteur_id);
CREATE INDEX idx_patrimoine_boites_gin ON patrimoine_documentaire USING GIN(types_boites);

-- Jonction porteuse d'attribut : Kobo `supports` (choix multiple) et les
-- volumétries conditionnelles vol_papier / nb_numerique / nb_audiovisuel /
-- nb_bande_magnetique / nb_plan / nb_carte.
CREATE TABLE patrimoine_support (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patrimoine_id   UUID NOT NULL REFERENCES patrimoine_documentaire(id) ON DELETE CASCADE,
  support         support_archive_enum NOT NULL,
  quantite        NUMERIC(12,2),
  -- Le papier se mesure en mètres linéaires, les autres supports en nombre
  -- d'unités : l'unité est donc portée par la ligne.
  unite           VARCHAR(20) NOT NULL DEFAULT 'nombre',
  precision       TEXT,

  CONSTRAINT uq_patrimoine_support UNIQUE (patrimoine_id, support),
  CONSTRAINT chk_patrimoine_support_quantite CHECK (quantite IS NULL OR quantite >= 0),
  CONSTRAINT chk_patrimoine_support_unite CHECK (unite IN ('nombre', 'metre_lineaire')),
  -- Kobo : `vol_papier` est en mètres linéaires, tous les autres sont des comptes.
  CONSTRAINT chk_patrimoine_support_unite_papier
    CHECK ((support = 'papier' AND unite = 'metre_lineaire')
        OR (support <> 'papier' AND unite = 'nombre')),
  CONSTRAINT chk_patrimoine_support_autres
    CHECK (support <> 'autres' OR precision IS NOT NULL)
);

CREATE INDEX idx_patrimoine_support_patrimoine ON patrimoine_support(patrimoine_id);
CREATE INDEX idx_patrimoine_support_type       ON patrimoine_support(support);

COMMENT ON TABLE patrimoine_support IS
  'Kobo IV.1 : chaque support coché déclenche la saisie de sa volumétrie. '
  'La contrainte chk_patrimoine_support_unite_papier impose les mètres linéaires '
  'pour le papier et le décompte pour les autres, conformément au formulaire.';

-- IV.4 Archives électroniques — Kobo groupe `grp_archives_elec`
CREATE TABLE archive_electronique (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patrimoine_id  UUID NOT NULL UNIQUE REFERENCES patrimoine_documentaire(id) ON DELETE CASCADE,

  -- Équipement — Kobo `serveur_flops`, `type_stockage`,
  -- `capacite_datacenter_to`, `capacite_occupee_to`
  serveur_flops           BIGINT,
  type_stockage           VARCHAR(200),
  capacite_datacenter_to  INTEGER,
  capacite_occupee_to     INTEGER,

  -- Kobo `sources_energie`, `sys_refroidissement`, `sites_replication`
  sources_energie      source_energie_enum[] NOT NULL DEFAULT '{}',
  sys_refroidissement  sys_refroidissement_enum[] NOT NULL DEFAULT '{}',
  sites_replication    SMALLINT,

  -- SAE — Kobo `nom_logiciel`, `typologie_logiciel`
  sae_nom_logiciel     VARCHAR(200),
  sae_typologie        typologie_logiciel_enum[] NOT NULL DEFAULT '{}',

  -- IV.4.1 Formats — Kobo `formats_fichiers`, `formats_autres`
  formats_fichiers     format_fichier_enum[] NOT NULL DEFAULT '{}',
  formats_autres       TEXT,

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_archive_elec_capacites CHECK (
    (capacite_datacenter_to IS NULL OR capacite_datacenter_to >= 0) AND
    (capacite_occupee_to IS NULL OR capacite_occupee_to >= 0) AND
    (capacite_occupee_to IS NULL OR capacite_datacenter_to IS NULL
     OR capacite_occupee_to <= capacite_datacenter_to)
  ),
  CONSTRAINT chk_archive_elec_replication CHECK (sites_replication IS NULL OR sites_replication >= 0),
  CONSTRAINT chk_archive_elec_flops CHECK (serveur_flops IS NULL OR serveur_flops >= 0),
  CONSTRAINT chk_archive_elec_formats_autres
    CHECK (NOT ('autres' = ANY(formats_fichiers)) OR formats_autres IS NOT NULL)
);

CREATE INDEX idx_archive_elec_formats_gin ON archive_electronique USING GIN(formats_fichiers);
CREATE INDEX idx_archive_elec_energie_gin ON archive_electronique USING GIN(sources_energie);

-- #############################################################################
-- SECTION V — Évaluation de la conservation (indicateurs de risque)
-- Kobo : groupe `risques` | SRS §12.6
-- #############################################################################

CREATE TABLE evaluation_conservation (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id  UUID NOT NULL UNIQUE REFERENCES producteur(id) ON DELETE CASCADE,

  -- V.1 — Kobo `etat_physique`, `etat_autre`
  etat_materiel        etat_materiel_enum[] NOT NULL DEFAULT '{}',
  etat_autre_precision TEXT,

  -- V.3 — Kobo `dispositifs_securite`
  dispositifs_securite dispositif_securite_enum[] NOT NULL DEFAULT '{}',

  -- V.4 — Kobo `risques_locaux`, `risque_autre`
  risques_environnementaux risque_environnemental_enum[] NOT NULL DEFAULT '{}',
  risque_autre_precision   TEXT,

  -- Indicateur dérivé, calculé au fichier 11 : sert au ciblage des inspections
  -- archivistiques (art. 31 à 34 de la Loi 2024/001).
  indice_risque SMALLINT,

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_eval_etat_autre
    CHECK (NOT ('autre' = ANY(etat_materiel)) OR etat_autre_precision IS NOT NULL),
  CONSTRAINT chk_eval_risque_autre
    CHECK (NOT ('autre' = ANY(risques_environnementaux)) OR risque_autre_precision IS NOT NULL),
  -- « Aucun dispositif » est exclusif de tout autre dispositif.
  CONSTRAINT chk_eval_dispositif_aucun_exclusif
    CHECK (NOT ('aucun' = ANY(dispositifs_securite)) OR array_length(dispositifs_securite, 1) = 1),
  CONSTRAINT chk_eval_indice_risque CHECK (indice_risque IS NULL OR indice_risque BETWEEN 0 AND 100)
);

CREATE INDEX idx_eval_etat_gin        ON evaluation_conservation USING GIN(etat_materiel);
CREATE INDEX idx_eval_risques_gin     ON evaluation_conservation USING GIN(risques_environnementaux);
CREATE INDEX idx_eval_dispositifs_gin ON evaluation_conservation USING GIN(dispositifs_securite);
CREATE INDEX idx_eval_indice_risque   ON evaluation_conservation(indice_risque DESC NULLS LAST);

COMMENT ON COLUMN evaluation_conservation.indice_risque IS
  'Indicateur dérivé de l''état matériel, des risques environnementaux et de '
  'l''absence de dispositifs de sécurité. Alimente FR-M3-08 (alertes sur les '
  'structures à risque) et le ciblage des inspections (art. 31-34 Loi 2024/001).';

-- #############################################################################
-- SECTION VI — Maturité de la gestion archivistique
-- Kobo : groupe `grp_maturite` | SRS §12.7 | Formule RG-M3-01 (annexe F)
-- #############################################################################

CREATE TABLE maturite_archivistique (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id  UUID NOT NULL UNIQUE REFERENCES producteur(id) ON DELETE CASCADE,

  -- VI.1 — Kobo `outils_gestion`
  outils_gestion outil_gestion_enum[] NOT NULL DEFAULT '{}',

  -- VI.2 — Kobo `niveau_validation`, `validation_autres`
  niveau_validation        niveau_validation_enum,
  validation_autre_precision TEXT,

  -- VI.3 — Kobo `instruments_recherche`
  instruments_recherche instrument_recherche_enum[] NOT NULL DEFAULT '{}',

  -- Critères complémentaires de la formule RG-M3-01 (annexe F), non couverts
  -- par le formulaire mais nécessaires au calcul de l'indice : ils sont
  -- renseignés par l'archiviste lors de la validation.
  service_archives_dedie BOOLEAN,
  personnel_forme        BOOLEAN,
  locaux_adaptes         BOOLEAN,

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_maturite_validation_autre
    CHECK (niveau_validation IS DISTINCT FROM 'autres' OR validation_autre_precision IS NOT NULL),
  CONSTRAINT chk_maturite_instrument_aucun_exclusif
    CHECK (NOT ('aucun' = ANY(instruments_recherche)) OR array_length(instruments_recherche, 1) = 1)
);

CREATE INDEX idx_maturite_producteur   ON maturite_archivistique(producteur_id);
CREATE INDEX idx_maturite_outils_gin   ON maturite_archivistique USING GIN(outils_gestion);
CREATE INDEX idx_maturite_instrum_gin  ON maturite_archivistique USING GIN(instruments_recherche);

COMMENT ON TABLE maturite_archivistique IS
  'Section VI du formulaire. Source de l''indice de maturité archivistique '
  'calculé par cnipac.calculer_score_maturite() selon la pondération RG-M3-01 : '
  'service dédié 25 %, personnel formé 15 %, locaux 20 %, plan de classement '
  '20 %, calendrier de conservation 10 %, instruments de recherche 10 %.';

-- VI.4 Éliminations — Kobo groupe `grp_elimination`.
-- Table 1:N : une structure peut avoir procédé à plusieurs éliminations
-- successives ; le formulaire n'en saisit que la dernière.
CREATE TABLE operation_elimination (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id  UUID NOT NULL REFERENCES producteur(id) ON DELETE CASCADE,

  annee            SMALLINT NOT NULL,     -- Kobo `annee_derniere_destruction`
  volume_elimine_ml NUMERIC(10,2),        -- Kobo `volume_elimine_ml`
  visa_elimination VARCHAR(200),          -- Kobo `visa_elimination`
  est_la_derniere  BOOLEAN NOT NULL DEFAULT TRUE,

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_elimination_annee
    CHECK (annee BETWEEN 1900 AND EXTRACT(YEAR FROM NOW())::SMALLINT),
  CONSTRAINT chk_elimination_volume CHECK (volume_elimine_ml IS NULL OR volume_elimine_ml >= 0)
);

CREATE INDEX idx_elimination_producteur ON operation_elimination(producteur_id);
CREATE UNIQUE INDEX uq_elimination_derniere
  ON operation_elimination(producteur_id) WHERE est_la_derniere;

COMMENT ON TABLE operation_elimination IS
  'Kobo VI.4. L''absence de ligne pour un producteur signifie « opération '
  'jamais réalisée » (Kobo `jamais_realisee` = oui) : l''information est portée '
  'par l''absence d''enregistrement, sans colonne booléenne redondante. '
  'L''élimination d''archives publiques est encadrée par la Loi 2024/001 : le '
  'visa est la référence de l''autorisation délivrée.';

-- #############################################################################
-- SECTION VII — Logistique et accessibilité pour le transfert
-- Kobo : groupe `grp_logistique` | SRS §12.8
-- #############################################################################

CREATE TABLE logistique_transfert (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id  UUID NOT NULL UNIQUE REFERENCES producteur(id) ON DELETE CASCADE,

  accessibilite_site       accessibilite_site_enum,              -- Kobo VII.1
  equipements_manutention  equipement_manutention_enum[] NOT NULL DEFAULT '{}',  -- VII.2
  conditionnement          conditionnement_enum[] NOT NULL DEFAULT '{}',         -- VII.3

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_logistique_equip_aucun_exclusif
    CHECK (NOT ('aucun' = ANY(equipements_manutention))
           OR array_length(equipements_manutention, 1) = 1)
);

CREATE INDEX idx_logistique_producteur ON logistique_transfert(producteur_id);
CREATE INDEX idx_logistique_equip_gin  ON logistique_transfert USING GIN(equipements_manutention);

COMMENT ON TABLE logistique_transfert IS
  'Section VII. Conditionne la planification des versements aux Archives '
  'Nationales : un site inaccessible aux camions impose une logistique '
  'particulière, à connaître avant d''ordonner un transfert.';

-- #############################################################################
-- SECTION VIII — Contact du répondant
-- Kobo : groupe `contact` | DONNÉES NOMINATIVES (NFR-C4-01)
-- #############################################################################

CREATE TABLE contact_repondant (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id  UUID NOT NULL REFERENCES producteur(id) ON DELETE CASCADE,

  nom_fonction   VARCHAR(255),   -- Kobo `nom_repondant`
  coordonnees    VARCHAR(255),   -- Kobo `tel_email` (champ libre du formulaire)
  telephone      VARCHAR(20),    -- extrait normalisé
  email          VARCHAR(100),   -- extrait normalisé

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_contact_email
    CHECK (email IS NULL OR email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

CREATE INDEX idx_contact_repondant_producteur ON contact_repondant(producteur_id);

COMMENT ON TABLE contact_repondant IS
  'DONNÉES NOMINATIVES — Section VIII du formulaire. Ces informations ne sont '
  'JAMAIS exposées par la carte publique ni par l''API non authentifiée '
  '(NFR-C4-01, RG-M2-02). Elles sont exclues par construction de la vue '
  'v_producteur_public (fichier 13). Conservation : durée de vie du producteur '
  'plus 5 ans (NFR-C4-03, art. 13 de la Loi 2024/001).';
