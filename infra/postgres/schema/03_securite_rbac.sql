-- =============================================================================
-- CNIPAC — 03 : sécurité et RBAC (domaine DOM-SEC)
-- Sources : SDD V4.0 §12.6 (table utilisateur, littérale), §12.9 (jonctions,
--           littérales), §11.4 (Session, MfaSecret) ; SRS V2.0 §6 (8 rôles,
--           ~60 permissions), §6.5 (politique de comptes).
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Utilisateur — DDL du SDD §12.6, transcription littérale.
-- Mot de passe haché Argon2id (NFR-C3-06), jamais en clair.
-- -----------------------------------------------------------------------------
CREATE TABLE utilisateur (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                    VARCHAR(100) NOT NULL UNIQUE,
  hash_password            VARCHAR(255) NOT NULL,  -- Argon2id encodé
  nom                      VARCHAR(100) NOT NULL,
  prenom                   VARCHAR(100) NOT NULL,
  structure                VARCHAR(200),

  statut                   statut_compte_enum NOT NULL DEFAULT 'actif',
  date_creation            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  dernier_login            TIMESTAMP WITH TIME ZONE,
  derniere_modif_password  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  mfa_active               BOOLEAN NOT NULL DEFAULT FALSE,
  tentatives_echouees      INTEGER NOT NULL DEFAULT 0,
  verrouille_jusqu_a       TIMESTAMP WITH TIME ZONE,

  created_at               TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at               TIMESTAMP WITH TIME ZONE,

  -- Complément : langue d'interface (NFR-C8-01, FR en P1, EN à partir de P2).
  locale                   VARCHAR(5) NOT NULL DEFAULT 'fr-CM',

  CONSTRAINT chk_utilisateur_email_format
    CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT chk_utilisateur_tentatives_max
    CHECK (tentatives_echouees >= 0 AND tentatives_echouees <= 100),
  CONSTRAINT chk_utilisateur_locale CHECK (locale IN ('fr-CM', 'en-CM'))
);

CREATE INDEX idx_utilisateur_statut ON utilisateur(statut);
CREATE UNIQUE INDEX idx_utilisateur_email_lower ON utilisateur(lower(email));

COMMENT ON COLUMN utilisateur.hash_password IS
  'Argon2id encodé (NFR-C3-06). Aucun mot de passe en clair ne transite ni ne '
  'réside en base, à aucun moment.';
COMMENT ON COLUMN utilisateur.verrouille_jusqu_a IS
  'FR-M6-05 : lorsque cette date est postérieure à NOW(), toute tentative '
  'd''authentification est bloquée (5 tentatives / 10 min — NFR-C3-08).';
COMMENT ON COLUMN utilisateur.deleted_at IS
  'Suppression logique. Un compte n''est jamais supprimé physiquement : ses '
  'traces au journal d''audit doivent rester rattachables (art. 32 Loi 2024/001).';

-- -----------------------------------------------------------------------------
-- Rôles — catalogue fermé de 8 entrées (SRS §6.2, AC-P1-06)
-- -----------------------------------------------------------------------------
CREATE TABLE role (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(20) NOT NULL UNIQUE,   -- R-01 .. R-08
  libelle_fr      VARCHAR(200) NOT NULL,
  libelle_en      VARCHAR(200) NOT NULL,
  description_fr  TEXT,
  description_en  TEXT,
  mfa_obligatoire BOOLEAN NOT NULL DEFAULT FALSE,   -- SRS §6.5.3 : obligatoire pour R-01
  ordre_affichage INTEGER NOT NULL,
  created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_role_code_format CHECK (code ~ '^R-0[1-8]$')
);

COMMENT ON TABLE role IS
  'Catalogue RBAC. Exactement 8 rôles R-01 à R-08 (SRS §6.2, AC-P1-06). '
  'La contrainte de format en interdit un neuvième sans migration.';

-- -----------------------------------------------------------------------------
-- Permissions élémentaires — ~60 entrées (SRS §6.3, nomenclature P-Mx-yy)
-- -----------------------------------------------------------------------------
CREATE TABLE permission (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(30) NOT NULL UNIQUE,   -- P-M1-01 ...
  module      module_enum NOT NULL,
  action      action_enum NOT NULL,
  ressource   VARCHAR(60) NOT NULL,
  perimetre   perimetre_enum NOT NULL DEFAULT 'global',
  libelle_fr  VARCHAR(255) NOT NULL,
  libelle_en  VARCHAR(255),
  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_permission_code_format CHECK (code ~ '^P-M[1-7]-[0-9]{2}$'),
  CONSTRAINT uq_permission_triplet UNIQUE (module, action, ressource, perimetre)
);

CREATE INDEX idx_permission_module ON permission(module);

COMMENT ON COLUMN permission.perimetre IS
  'Restreint la portée d''une permission : « ma_structure » pour un point focal '
  '(R-05), « ma_region » pour un agent régional. Cf. SRS §6.4.1.';

-- -----------------------------------------------------------------------------
-- Jonctions RBAC — DDL du SDD §12.9, transcription littérale.
-- Aucune permission n'est jamais attribuée directement à un utilisateur :
-- uniquement via un rôle (SDD §11.4, modèle NIST INCITS 359-2012).
-- -----------------------------------------------------------------------------
CREATE TABLE utilisateur_role (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id  UUID NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  role_id         UUID NOT NULL REFERENCES role(id) ON DELETE RESTRICT,
  octroye_par     UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  octroye_le      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  motif_octroi    TEXT,
  revoque_le      TIMESTAMP WITH TIME ZONE,

  CONSTRAINT uq_utilisateur_role UNIQUE(utilisateur_id, role_id),
  CONSTRAINT chk_utilisateur_role_revocation CHECK (revoque_le IS NULL OR revoque_le >= octroye_le)
);

CREATE INDEX idx_utilisateur_role_utilisateur ON utilisateur_role(utilisateur_id);
CREATE INDEX idx_utilisateur_role_role        ON utilisateur_role(role_id);
CREATE INDEX idx_utilisateur_role_actifs      ON utilisateur_role(utilisateur_id) WHERE revoque_le IS NULL;

CREATE TABLE role_permission (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id       UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permission(id) ON DELETE CASCADE,
  created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_role_permission UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_role_permission_role       ON role_permission(role_id);
CREATE INDEX idx_role_permission_permission ON role_permission(permission_id);

-- -----------------------------------------------------------------------------
-- Sessions — SDD §11.4 : « stocke les JWT actifs et révoqués (cache Redis pour
-- la performance, persistance PostgreSQL pour la durabilité) ».
-- C'est la source de vérité de la révocation : Redis n'en est que le cache.
-- -----------------------------------------------------------------------------
CREATE TABLE session (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id    UUID NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  jti               VARCHAR(64) NOT NULL UNIQUE,   -- identifiant du JWT (RFC 7519)
  emis_le           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  expire_le         TIMESTAMP WITH TIME ZONE NOT NULL,
  revoque_le        TIMESTAMP WITH TIME ZONE,
  motif_revocation  VARCHAR(120),
  ip_source         INET,
  user_agent        TEXT,

  CONSTRAINT chk_session_expiration CHECK (expire_le > emis_le)
);

CREATE INDEX idx_session_utilisateur ON session(utilisateur_id);
CREATE INDEX idx_session_revoquees   ON session(jti) WHERE revoque_le IS NOT NULL;
CREATE INDEX idx_session_expire_le   ON session(expire_le);

COMMENT ON TABLE session IS
  'Source de vérité de la révocation des jetons. Redis (base 2) en est le cache '
  'rapide ; en cas de redémarrage de Redis, la liste est rechargée depuis cette '
  'table — sans quoi les jetons révoqués redeviendraient valides.';

-- -----------------------------------------------------------------------------
-- Secrets MFA (TOTP RFC 6238) — SDD §11.4 et §23.3.
-- Le secret est chiffré applicativement par une clé distincte (ADR-010 du SDD) :
-- la base ne voit jamais le secret en clair.
-- -----------------------------------------------------------------------------
CREATE TABLE mfa_secret (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id      UUID NOT NULL UNIQUE REFERENCES utilisateur(id) ON DELETE CASCADE,
  secret_chiffre      TEXT NOT NULL,
  cle_chiffrement_ref VARCHAR(80) NOT NULL,
  codes_secours       TEXT[],           -- hachés, jamais en clair
  active_le           TIMESTAMP WITH TIME ZONE,
  created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE mfa_secret IS
  'Un seul secret MFA actif par utilisateur (contrainte UNIQUE, SDD §11.4). '
  'Secret chiffré par une clé séparée, gérée par Docker secrets (ADR-010).';
