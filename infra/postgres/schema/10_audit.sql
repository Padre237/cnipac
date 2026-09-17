-- =============================================================================
-- CNIPAC — 10 : journal d'audit (domaine DOM-AUD)
-- Source : SDD V4.0 §12.7, transcription LITTÉRALE. ADR-009 du SDD.
--
-- TABLE PROTÉGÉE — art. 32 de la Loi n° 2024/001 (immuabilité du journal),
-- NFR-C3-05 (conservation 5 ans sans possibilité de purge anticipée).
-- Aucune migration destructive n'est admise (ADR-027).
-- =============================================================================
SET search_path TO cnipac, public;

CREATE TABLE evenement_audit (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sequence         BIGSERIAL NOT NULL UNIQUE,
  horodatage       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  utilisateur_id   UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  role_utilise     VARCHAR(20),

  action           VARCHAR(100) NOT NULL,
  ressource_type   VARCHAR(50) NOT NULL,
  ressource_id     UUID,

  payload_avant    JSONB,
  payload_apres    JSONB,

  ip_source        INET,
  user_agent       TEXT,
  session_id       UUID,

  prev_hash        CHAR(64),
  hash             CHAR(64) NOT NULL
);

CREATE INDEX idx_evenement_audit_horodatage    ON evenement_audit(horodatage DESC);
CREATE INDEX idx_evenement_audit_utilisateur   ON evenement_audit(utilisateur_id);
CREATE INDEX idx_evenement_audit_action        ON evenement_audit(action);
CREATE INDEX idx_evenement_audit_ressource     ON evenement_audit(ressource_type, ressource_id);

COMMENT ON TABLE evenement_audit IS
  'Journal d''audit INSERT-ONLY avec chaînage par hachage SHA-256 (ADR-009). '
  'Article 32 de la Loi 2024/001 : immuabilité. NFR-C3-05 : conservation 5 ans '
  'sans purge anticipée. Toute altération d''un enregistrement rompt la chaîne '
  'en aval et devient détectable.';
COMMENT ON COLUMN evenement_audit.role_utilise IS
  'Snapshot TEXTUEL du code de rôle, et non une clé étrangère : la trace doit '
  'survivre à la suppression éventuelle du rôle (SDD §11.8).';
COMMENT ON COLUMN evenement_audit.prev_hash IS
  'Hachage de l''événement de séquence immédiatement inférieure. NULL pour le '
  'tout premier enregistrement uniquement.';

-- -----------------------------------------------------------------------------
-- Méta-audit : résultat des vérifications périodiques de la chaîne.
-- SDD §11.5 : « une procédure de vérification (job mensuel) parcourt la séquence
-- et valide la chaîne, en consignant le résultat dans un journal de méta-audit ».
-- -----------------------------------------------------------------------------
CREATE TABLE verification_chaine_audit (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execute_le          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  sequence_debut      BIGINT NOT NULL,
  sequence_fin        BIGINT NOT NULL,
  nb_evenements       BIGINT NOT NULL,
  chaine_intacte      BOOLEAN NOT NULL,
  premiere_rupture_seq BIGINT,
  duree_ms            INTEGER,
  declenche_par       VARCHAR(60) NOT NULL DEFAULT 'job_mensuel',

  CONSTRAINT chk_verification_sequences CHECK (sequence_fin >= sequence_debut),
  CONSTRAINT chk_verification_rupture
    CHECK (chaine_intacte = TRUE OR premiere_rupture_seq IS NOT NULL)
);

CREATE INDEX idx_verification_chaine_execute ON verification_chaine_audit(execute_le DESC);
CREATE INDEX idx_verification_chaine_rupture ON verification_chaine_audit(execute_le DESC)
  WHERE chaine_intacte = FALSE;

COMMENT ON TABLE verification_chaine_audit IS
  'Journal de méta-audit. Une ligne avec chaine_intacte = FALSE est l''événement '
  'le plus grave du système : elle déclenche l''alerte de criticité maximale '
  'CnipacChaineAuditRompue et le runbook RB-09.';
