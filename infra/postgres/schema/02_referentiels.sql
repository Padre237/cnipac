-- =============================================================================
-- CNIPAC — 02 : référentiels
-- Sources : SDD V4.0 §12.8 (DDL reproduit à la lettre), SRS V2.0 §12.10,
--           formulaire KoboToolbox (feuille `choices`, listes region /
--           departement / arrondissement).
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Réseaux archivistiques — 9 entrées (SND30, TDR §7, annexe E du SRS)
-- DDL : SDD §12.8, transcription littérale.
-- -----------------------------------------------------------------------------
CREATE TABLE reseau_archivistique (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code              VARCHAR(20) NOT NULL UNIQUE,
  libelle_fr        VARCHAR(200) NOT NULL,
  libelle_en        VARCHAR(200) NOT NULL,
  description_fr    TEXT,
  description_en    TEXT,
  ordre_affichage   INTEGER NOT NULL,
  created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_reseau_archivistique_ordre UNIQUE (ordre_affichage),
  CONSTRAINT chk_reseau_archivistique_ordre CHECK (ordre_affichage BETWEEN 1 AND 9)
);

COMMENT ON TABLE reseau_archivistique IS
  'Les 9 réseaux archivistiques de la SND30 (TDR §7). Le nombre est fermé : la '
  'contrainte chk_reseau_archivistique_ordre en interdit un dixième sans migration.';

-- -----------------------------------------------------------------------------
-- Ministères — ~40 entrées (référentiel SIGIPES / Présidence, SRS §12.10)
-- DDL : SDD §12.8, transcription littérale.
-- -----------------------------------------------------------------------------
CREATE TABLE ministere (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(20) NOT NULL UNIQUE,
  libelle_fr  VARCHAR(255) NOT NULL,
  libelle_en  VARCHAR(255) NOT NULL,
  sigle       VARCHAR(20) NOT NULL,
  statut      VARCHAR(20) NOT NULL DEFAULT 'actif',
  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Complément : RG-M2-04 calcule le réseau d'un producteur à partir de son
  -- ministère de tutelle et de son statut administratif. Le rattachement par
  -- défaut est donc porté par le référentiel lui-même.
  reseau_defaut_id UUID REFERENCES reseau_archivistique(id) ON DELETE RESTRICT,

  CONSTRAINT chk_ministere_statut CHECK (statut IN ('actif', 'supprime', 'fusionne', 'renomme')),
  CONSTRAINT uq_ministere_sigle UNIQUE (sigle)
);

CREATE INDEX idx_ministere_statut ON ministere(statut);
CREATE INDEX idx_ministere_reseau_defaut_id ON ministere(reseau_defaut_id);

COMMENT ON COLUMN ministere.reseau_defaut_id IS
  'Réseau archivistique par défaut des structures rattachées à ce ministère. '
  'Support de la règle de gestion RG-M2-04 (calcul automatique du réseau).';
COMMENT ON COLUMN ministere.statut IS
  'Un remaniement gouvernemental ne SUPPRIME jamais un ministère : il le marque '
  '« supprime », « fusionne » ou « renomme ». Les fiches historiques conservent '
  'ainsi leur rattachement (SRS §12.10).';

-- -----------------------------------------------------------------------------
-- Découpage administratif — hiérarchie récursive
-- DDL : SDD §12.8, transcription littérale, complétée par les champs
-- nécessaires à l'alimentation depuis le formulaire Kobo.
-- Volumétrie réelle du formulaire : 10 régions, 58 départements,
-- 290 arrondissements (SRS §12.10 annonce ~360 communes).
-- -----------------------------------------------------------------------------
CREATE TABLE unite_admin (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         VARCHAR(20) NOT NULL UNIQUE,
  libelle      VARCHAR(200) NOT NULL,
  niveau       niveau_unite_admin_enum NOT NULL,
  parent_id    UUID REFERENCES unite_admin(id) ON DELETE RESTRICT,
  geom_polygon geometry(MultiPolygon, 4326),
  created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Compléments d'alimentation depuis la feuille `choices` du XLSForm :
  -- le code Kobo est conservé pour garantir l'idempotence de l'ingestion M1.
  code_kobo    VARCHAR(80),
  chef_lieu    VARCHAR(120),

  -- Une unité non nationale a toujours un parent ; le niveau national n'en a pas.
  CONSTRAINT chk_unite_admin_hierarchie
    CHECK ((niveau = 'national' AND parent_id IS NULL)
        OR (niveau <> 'national' AND parent_id IS NOT NULL)),
  CONSTRAINT chk_unite_admin_pas_son_propre_parent CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE INDEX idx_unite_admin_parent_id ON unite_admin(parent_id);
CREATE INDEX idx_unite_admin_niveau    ON unite_admin(niveau);
CREATE INDEX idx_unite_admin_geom      ON unite_admin USING GIST(geom_polygon);
CREATE UNIQUE INDEX uq_unite_admin_code_kobo_niveau
  ON unite_admin(code_kobo, niveau) WHERE code_kobo IS NOT NULL;

COMMENT ON TABLE unite_admin IS
  'Découpage administratif du Cameroun, hiérarchie récursive '
  'national > region > departement > arrondissement. Alimenté depuis la feuille '
  '`choices` du formulaire KoboToolbox (10 / 58 / 290).';
COMMENT ON COLUMN unite_admin.code_kobo IS
  'Code tel qu''il figure dans le XLSForm (colonne `name`). Garantit '
  'l''idempotence du rapprochement lors de l''ingestion M1.';

-- -----------------------------------------------------------------------------
-- Nomenclature ouverte — libellés bilingues des listes du formulaire
--
-- Les valeurs elles-mêmes sont des types ENUM (fichier 01), ce qui garantit
-- l'intégrité au niveau base conformément au SDD §12.2. Cette table porte
-- UNIQUEMENT leurs libellés d'affichage FR/EN, que les administrateurs métier
-- peuvent modifier sans migration (SRS §12.10, NFR-C8-01).
-- -----------------------------------------------------------------------------
CREATE TABLE nomenclature (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  liste           VARCHAR(60) NOT NULL,   -- nom du type ENUM, ex. 'support_archive_enum'
  code            VARCHAR(60) NOT NULL,   -- valeur de l'ENUM, ex. 'papier'
  libelle_fr      VARCHAR(255) NOT NULL,
  libelle_en      VARCHAR(255),
  ordre_affichage INTEGER NOT NULL DEFAULT 0,
  actif           BOOLEAN NOT NULL DEFAULT TRUE,
  source          VARCHAR(80) NOT NULL DEFAULT 'xlsform',  -- traçabilité de l'origine
  created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_nomenclature_liste_code UNIQUE (liste, code)
);

CREATE INDEX idx_nomenclature_liste ON nomenclature(liste) WHERE actif;

COMMENT ON TABLE nomenclature IS
  'Libellés bilingues des listes contrôlées. Les VALEURS sont des ENUM PostgreSQL '
  '(SDD §12.2) ; seuls les libellés d''affichage vivent ici, modifiables par les '
  'administrateurs métier sans migration de schéma (SRS §12.10).';
