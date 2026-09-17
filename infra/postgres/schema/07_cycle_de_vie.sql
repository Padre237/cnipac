-- =============================================================================
-- CNIPAC — 07 : versionnage des fiches (domaine DOM-CYC)
-- Source : SDD V4.0 §12.4, transcription LITTÉRALE. ADR-006 du SDD : versionnage
-- par table + JSONB, l'event sourcing ayant été écarté.
--
-- TABLE PROTÉGÉE (ADR-027) : aucune migration destructive n'est admise.
-- =============================================================================
SET search_path TO cnipac, public;

CREATE TABLE version_fiche (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id            UUID NOT NULL REFERENCES producteur(id) ON DELETE CASCADE,
  num_version              INTEGER NOT NULL,
  payload                  JSONB NOT NULL,
  cree_par                 UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  cree_le                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  motif                    TEXT,
  piece_justificative_id   UUID REFERENCES piece_jointe(id) ON DELETE SET NULL,

  CONSTRAINT uq_version_fiche_producteur_num UNIQUE (producteur_id, num_version),
  CONSTRAINT chk_version_fiche_num_positif CHECK (num_version > 0)
);

CREATE INDEX idx_version_fiche_producteur_id ON version_fiche(producteur_id);
CREATE INDEX idx_version_fiche_cree_le       ON version_fiche(cree_le DESC);
CREATE INDEX idx_version_fiche_payload_gin   ON version_fiche USING GIN(payload jsonb_path_ops);

COMMENT ON TABLE version_fiche IS
  'Historique des versions d''une fiche producteur. Conformément à ADR-006, payload JSONB complet par version.';
COMMENT ON COLUMN version_fiche.payload IS
  'Instantané COMPLET de la fiche à cette version, sections III à VIII comprises. '
  'Permet UC-M4-07 (consulter l''historique) et UC-M4-08 (restaurer une version). '
  'La comparaison de deux versions s''effectue par jsonb_diff (SDD §16.3.2).';
