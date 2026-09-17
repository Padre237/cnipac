-- =============================================================================
-- CNIPAC — 04 : table centrale `producteur` (domaine DOM-IDF)
--
-- Le bloc principal est la transcription LITTÉRALE du DDL du SDD V4.0 §12.3.
-- Les champs ajoutés en fin de table couvrent la Section II du formulaire
-- KoboToolbox et du SRS §12.3 que le DDL du SDD ne détaille pas ; ils relèvent
-- de l'Annexe A annoncée par le SDD §12 et non fournie. Chacun porte sa source.
-- =============================================================================
SET search_path TO cnipac, public;

CREATE TABLE producteur (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_producteur     VARCHAR(50)  NOT NULL UNIQUE,
  nom_officiel        TEXT         NOT NULL,
  sigle               VARCHAR(20)  NOT NULL,
  noms_paralleles     TEXT[],
  date_creation       DATE,
  texte_fondateur     TEXT,
  mission             TEXT,

  type_entite         type_entite_enum   NOT NULL,
  statut_admin        statut_admin_enum  NOT NULL,

  -- Localisation
  geom                geometry(Point, 4326),
  adresse             TEXT,
  telephone           VARCHAR(20),
  email               VARCHAR(100),
  site_web            VARCHAR(200),

  -- Référentiels
  reseau_id           UUID NOT NULL REFERENCES reseau_archivistique(id) ON DELETE RESTRICT,
  ministere_id        UUID NOT NULL REFERENCES ministere(id) ON DELETE RESTRICT,
  commune_id          UUID NOT NULL REFERENCES unite_admin(id) ON DELETE RESTRICT,

  -- Cycle de vie
  statut_fiche        statut_fiche_enum NOT NULL DEFAULT 'nouvelle',
  version_courante    INTEGER NOT NULL DEFAULT 1,
  kobo_instance_id    VARCHAR(100), -- traçabilité de la soumission origine

  -- Métadonnées techniques
  created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMP WITH TIME ZONE,

  -- ===========================================================================
  -- COMPLÉMENTS — Section II du formulaire Kobo et SRS §12.3 / §12.9
  -- ===========================================================================

  -- SRS §12.3 II.3 « Précision GPS (m) », entier >= 1. Kobo geopoint le fournit.
  precision_gps_m     INTEGER,

  -- Kobo II.3 « Adresse physique complète » : le formulaire décompose l'adresse.
  -- Le champ `adresse` du SDD conserve la forme libre reconstituée.
  quartier            VARCHAR(200),   -- Kobo `quartier`   / SRS II.8
  boite_postale       VARCHAR(50),    -- Kobo `bp`
  rue                 VARCHAR(200),   -- Kobo `rue`
  lieu_dit            VARCHAR(200),   -- Kobo `lieu_dit`

  -- Kobo II.3 : le formulaire saisit région, département ET arrondissement.
  -- `commune_id` (SDD) porte l'arrondissement ; les deux niveaux supérieurs sont
  -- dénormalisés ici car ils filtrent la carte et les tableaux de bord
  -- (FR-M2-02, FR-M3-02). Cohérence garantie par trigger (fichier 12).
  region_id           UUID REFERENCES unite_admin(id) ON DELETE RESTRICT,
  departement_id      UUID REFERENCES unite_admin(id) ON DELETE RESTRICT,

  -- Kobo I.2 « Type d'organisation » : nomenclature du terrain, conservée telle
  -- quelle en plus de `type_entite` (nomenclature SRS §12.10).
  type_organisation   type_organisation_enum,

  -- Kobo I.3 « Rôle de l'institution », I.4 « Code unique administratif ».
  role_institution    TEXT,
  code_admin_externe  VARCHAR(80),

  -- SRS §12.9 métadonnées techniques MT.08, MT.10, MT.11, MT.13.
  date_validation             TIMESTAMP WITH TIME ZONE,
  valide_par                  UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  derniere_maj_par            UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  tags                        TEXT[],

  -- Traçabilité de l'origine de la fiche (ingestion M1).
  source_ingestion    source_ingestion_enum NOT NULL DEFAULT 'kobo',

  -- Indice de maturité archivistique (RG-M3-01), recalculé à chaque validation.
  score_maturite      SMALLINT,

  -- ===========================================================================
  -- Contraintes métier — bloc du SDD §12.3, transcription littérale
  -- ===========================================================================
  CONSTRAINT chk_producteur_code_producteur_format
    CHECK (code_producteur ~ '^CMR-[A-Z0-9]+-[A-Z0-9]+-[A-Z0-9]+-[0-9]+$'),
  CONSTRAINT chk_producteur_geom_in_cameroun
    CHECK (
      geom IS NULL OR (
        ST_X(geom) BETWEEN 8.5 AND 16.2 AND
        ST_Y(geom) BETWEEN 1.6 AND 13.1
      )
    ),
  CONSTRAINT chk_producteur_email_format
    CHECK (email IS NULL OR email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT chk_producteur_telephone_format
    CHECK (telephone IS NULL OR telephone ~ '^\+237[0-9]{8,12}$'),

  -- Contraintes complémentaires
  CONSTRAINT chk_producteur_precision_gps CHECK (precision_gps_m IS NULL OR precision_gps_m >= 1),
  CONSTRAINT chk_producteur_version_positive CHECK (version_courante > 0),
  CONSTRAINT chk_producteur_score_maturite CHECK (score_maturite IS NULL OR score_maturite BETWEEN 0 AND 100),
  CONSTRAINT chk_producteur_site_web CHECK (site_web IS NULL OR site_web ~* '^https?://'),
  -- Une fiche validée porte nécessairement sa date et son auteur de validation.
  CONSTRAINT chk_producteur_validation_coherente
    CHECK (statut_fiche NOT IN ('validee', 'editee') OR date_validation IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- Index — bloc du SDD §12.3, transcription littérale, puis compléments
-- -----------------------------------------------------------------------------
CREATE INDEX idx_producteur_reseau_id       ON producteur(reseau_id);
CREATE INDEX idx_producteur_ministere_id    ON producteur(ministere_id);
CREATE INDEX idx_producteur_commune_id      ON producteur(commune_id);
CREATE INDEX idx_producteur_statut_fiche    ON producteur(statut_fiche);
CREATE INDEX idx_producteur_geom_gist       ON producteur USING GIST(geom);
CREATE INDEX idx_producteur_search_fts      ON producteur
  USING GIN (to_tsvector('french', nom_officiel || ' ' || sigle));

-- Compléments d'indexation (SDD §12.13.2)
CREATE INDEX idx_producteur_region_id       ON producteur(region_id);
CREATE INDEX idx_producteur_departement_id  ON producteur(departement_id);

-- FR-M2-02 : filtrage croisé réseau × région sur la carte publique.
-- Index partiel : seules les fiches affichables sont concernées (RG-M2-01).
CREATE INDEX idx_producteur_carte_publique
  ON producteur(reseau_id, region_id, ministere_id)
  WHERE statut_fiche IN ('validee', 'editee') AND deleted_at IS NULL;

-- UC-M2-04 : recherche par nom, sigle ou code, tolérante aux fautes de frappe.
CREATE INDEX idx_producteur_sigle_trgm ON producteur USING GIN (sigle gin_trgm_ops);
CREATE INDEX idx_producteur_nom_trgm   ON producteur USING GIN (nom_officiel gin_trgm_ops);

-- RG-M1-03 : détection de doublons sur le triplet (sigle, ministère, commune).
CREATE INDEX idx_producteur_triplet_doublon
  ON producteur(upper(sigle), ministere_id, commune_id)
  WHERE deleted_at IS NULL;

-- DQ-02 : le sigle doit être unique dans le périmètre de son ministère.
CREATE UNIQUE INDEX uq_producteur_sigle_ministere
  ON producteur(upper(sigle), ministere_id)
  WHERE deleted_at IS NULL AND statut_fiche IN ('validee', 'editee');

-- Traçabilité de l'origine : une soumission Kobo ne produit qu'une fiche.
CREATE UNIQUE INDEX uq_producteur_kobo_instance
  ON producteur(kobo_instance_id) WHERE kobo_instance_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- Commentaires — bloc du SDD §12.3, complété
-- -----------------------------------------------------------------------------
COMMENT ON TABLE producteur IS
  'Table centrale : fiche d''identification d''un producteur d''archives publiques. Cf. SRS V2.0 §12.2.';
COMMENT ON COLUMN producteur.code_producteur IS
  'Code métier unique format CMR-<RÉSEAU>-<MIN>-<STRUCT>-<SEQ>. Généré automatiquement (FR-M1-06). '
  'Immuable à vie (RG-M1-02) : il fonde la pérennité des URI de l''API publique (FR-M7-04).';
COMMENT ON COLUMN producteur.geom IS
  'Géométrie PostGIS, projection WGS84 (EPSG:4326). Doit être à l''intérieur du Cameroun.';
COMMENT ON COLUMN producteur.statut_fiche IS
  'Automate RG-M1-05 : nouvelle > quarantaine > validee > (editee)* > archivee. '
  'Aucune transition arrière sans intervention tracée d''un super-administrateur. '
  'Transitions contrôlées par trigger (fichier 12_triggers.sql).';
COMMENT ON COLUMN producteur.score_maturite IS
  'Indice de maturité archivistique sur 100, formule pondérée RG-M3-01 (annexe F). '
  'Recalculé par cnipac.calculer_score_maturite() à chaque validation.';
COMMENT ON CONSTRAINT chk_producteur_geom_in_cameroun ON producteur IS
  'RG-M2-03 et DQ-01. Une fiche hors enveloppe n''est PAS cartographiée mais reste '
  'consultable en liste — d''où une géométrie nullable plutôt qu''un rejet.';
