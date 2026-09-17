-- =============================================================================
-- CNIPAC — 09 : crowdsourcing sécurisé (domaine DOM-CRW)
-- Sources : SDD V4.0 §11.6, SRS V2.0 §5.5 et §11.5 (RG-M5-01 à RG-M5-05),
--           art. 19 de la Loi 2024/001 (correspondants archives).
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Point focal archives (rôle R-05)
-- RG-M5-01 : « un point focal est strictement rattaché à UNE structure
-- productrice » — le cloisonnement est matérialisé par une contrainte forte.
-- -----------------------------------------------------------------------------
CREATE TABLE point_focal (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id   UUID NOT NULL UNIQUE REFERENCES utilisateur(id) ON DELETE CASCADE,
  producteur_id    UUID NOT NULL REFERENCES producteur(id) ON DELETE RESTRICT,

  statut           statut_point_focal_enum NOT NULL DEFAULT 'designe_en_attente',

  -- Art. 19 de la Loi 2024/001 : le correspondant archives est officiellement
  -- désigné. La lettre de désignation est la pièce justificative de ce statut.
  lettre_designation_id UUID REFERENCES piece_jointe(id) ON DELETE SET NULL,
  date_designation      DATE,
  fonction              VARCHAR(200),

  designe_par      UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  active_le        TIMESTAMP WITH TIME ZONE,
  derniere_activite TIMESTAMP WITH TIME ZONE,
  desactive_le     TIMESTAMP WITH TIME ZONE,
  motif_desactivation TEXT,

  -- FR-M5-09 : indice de réputation, alimenté par le taux d'acceptation des
  -- propositions. Livré en P3.
  score_reputation SMALLINT,

  created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_point_focal_actif_date
    CHECK (statut <> 'actif' OR active_le IS NOT NULL),
  CONSTRAINT chk_point_focal_desactive_motive
    CHECK (statut <> 'desactive' OR motif_desactivation IS NOT NULL),
  CONSTRAINT chk_point_focal_reputation
    CHECK (score_reputation IS NULL OR score_reputation BETWEEN 0 AND 100)
);

CREATE INDEX idx_point_focal_producteur ON point_focal(producteur_id);
CREATE INDEX idx_point_focal_statut     ON point_focal(statut);
-- Un producteur peut avoir plusieurs points focaux successifs, mais un seul actif.
CREATE UNIQUE INDEX uq_point_focal_actif_par_producteur
  ON point_focal(producteur_id) WHERE statut = 'actif';

COMMENT ON TABLE point_focal IS
  'Correspondant archives au sens de l''article 19 de la Loi 2024/001. '
  'RG-M5-01 : rattachement strict à une seule structure. La contrainte UNIQUE '
  'sur utilisateur_id garantit qu''un compte ne peut être point focal de deux '
  'structures — c''est la base du cloisonnement des données du module M5.';

-- -----------------------------------------------------------------------------
-- Proposition de mise à jour (UC-M5-03)
-- SDD §11.6 : « le champ payload_modifications contient le DELTA proposé
-- (champ par champ), pas la fiche complète », afin que l'archiviste puisse
-- accepter ou refuser modification par modification.
-- -----------------------------------------------------------------------------
CREATE TABLE proposition_maj (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id         UUID NOT NULL REFERENCES producteur(id) ON DELETE CASCADE,
  point_focal_id        UUID NOT NULL REFERENCES point_focal(id) ON DELETE RESTRICT,

  payload_modifications JSONB NOT NULL,
  commentaire_auteur    TEXT,
  piece_justificative_id UUID REFERENCES piece_jointe(id) ON DELETE SET NULL,

  statut                statut_proposition_enum NOT NULL DEFAULT 'en_attente',
  soumise_le            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- RG-M5-05 : délai de traitement de 30 jours, calculé à la création.
  date_limite_traitement TIMESTAMP WITH TIME ZONE NOT NULL
                         DEFAULT (NOW() + INTERVAL '30 days'),

  traitee_par           UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  traitee_le            TIMESTAMP WITH TIME ZONE,
  motif_decision        TEXT,
  -- Champs effectivement retenus lors d'une acceptation partielle.
  champs_acceptes       TEXT[],
  version_generee_id    UUID REFERENCES version_fiche(id) ON DELETE SET NULL,

  CONSTRAINT chk_proposition_delta_non_vide
    CHECK (jsonb_typeof(payload_modifications) = 'object'
           AND payload_modifications <> '{}'::jsonb),
  CONSTRAINT chk_proposition_traitement_coherent
    CHECK (statut = 'en_attente' OR traitee_le IS NOT NULL),
  CONSTRAINT chk_proposition_refus_motive
    CHECK (statut <> 'refusee' OR motif_decision IS NOT NULL),
  CONSTRAINT chk_proposition_limite_posterieure
    CHECK (date_limite_traitement > soumise_le)
);

CREATE INDEX idx_proposition_producteur  ON proposition_maj(producteur_id);
CREATE INDEX idx_proposition_point_focal ON proposition_maj(point_focal_id);
CREATE INDEX idx_proposition_statut      ON proposition_maj(statut);
CREATE INDEX idx_proposition_delta_gin   ON proposition_maj USING GIN(payload_modifications jsonb_path_ops);
-- File d'attente d'examen (UC-M5-04), ordonnée par échéance : le job nocturne
-- signale les propositions arrivant à expiration (SDD §11.6).
CREATE INDEX idx_proposition_en_attente
  ON proposition_maj(date_limite_traitement)
  WHERE statut IN ('en_attente', 'complement_demande');

COMMENT ON COLUMN proposition_maj.payload_modifications IS
  'DELTA champ par champ, jamais la fiche complète (SDD §11.6). Permet '
  'l''acceptation partielle : les champs retenus sont listés dans champs_acceptes.';
COMMENT ON COLUMN proposition_maj.statut IS
  'Voir la note de conformité du type statut_proposition_enum : la valeur '
  '« accepteee » comporte trois « e », telle qu''elle figure au SDD §12.2.';
