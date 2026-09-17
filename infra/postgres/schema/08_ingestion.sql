-- =============================================================================
-- CNIPAC — 08 : ingestion KoboToolbox (domaine DOM-ING)
-- Sources : SDD V4.0 §12.5 (soumission_kobo, LITTÉRALE), §11.3 (lot d'ingestion,
--           journal d'ingestion), SRS V2.0 §11.1 (RG-M1-01 à RG-M1-05).
--
-- TABLE PROTÉGÉE (ADR-027) : `soumission_kobo` est IMMUABLE — RG-M1-04.
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Lot d'ingestion — une exécution du connecteur ou un import de fichier.
-- Référencé par soumission_kobo dans le DDL du SDD §12.5, sans DDL propre :
-- défini ici (Annexe A).
-- -----------------------------------------------------------------------------
CREATE TABLE lot_ingestion (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source              source_ingestion_enum NOT NULL DEFAULT 'kobo',
  kobo_form_id        VARCHAR(50),
  fichier_origine     VARCHAR(255),      -- pour un import CSV/Excel (UC-M1-03)

  statut              statut_lot_enum NOT NULL DEFAULT 'en_cours',
  debut_le            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  fin_le              TIMESTAMP WITH TIME ZONE,

  nb_recues           INTEGER NOT NULL DEFAULT 0,
  nb_integrees        INTEGER NOT NULL DEFAULT 0,
  nb_rejetees         INTEGER NOT NULL DEFAULT 0,
  nb_doublons         INTEGER NOT NULL DEFAULT 0,

  -- Curseur de synchronisation incrémentale (SDD §13.3.1) : permet de ne
  -- récupérer que les soumissions postérieures au dernier lot réussi.
  curseur_depuis      TIMESTAMP WITH TIME ZONE,
  curseur_jusqu_a     TIMESTAMP WITH TIME ZONE,

  declenche_par       UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  message_erreur      TEXT,

  CONSTRAINT chk_lot_ingestion_compteurs CHECK (
    nb_recues >= 0 AND nb_integrees >= 0 AND nb_rejetees >= 0 AND nb_doublons >= 0
    AND nb_integrees + nb_rejetees + nb_doublons <= nb_recues
  ),
  CONSTRAINT chk_lot_ingestion_fin CHECK (fin_le IS NULL OR fin_le >= debut_le),
  CONSTRAINT chk_lot_ingestion_termine CHECK (statut = 'en_cours' OR fin_le IS NOT NULL)
);

CREATE INDEX idx_lot_ingestion_statut  ON lot_ingestion(statut);
CREATE INDEX idx_lot_ingestion_debut   ON lot_ingestion(debut_le DESC);

COMMENT ON TABLE lot_ingestion IS
  'Une exécution du connecteur Kobo ou un import manuel. Alimente le journal '
  'd''ingestion consultable par UC-M1-04 et l''alerte de synchronisation '
  'interrompue (FR-M1-01 : soumission en quarantaine en moins de 15 minutes).';

-- -----------------------------------------------------------------------------
-- Soumission KoboToolbox — DDL du SDD §12.5, transcription littérale,
-- complétée des champs du formulaire (date de remplissage, enquêteur).
-- -----------------------------------------------------------------------------
CREATE TABLE soumission_kobo (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kobo_instance_id         VARCHAR(100) NOT NULL UNIQUE,
  kobo_form_id             VARCHAR(50) NOT NULL,
  payload                  JSONB NOT NULL,
  date_soumission_kobo     TIMESTAMP WITH TIME ZONE NOT NULL,
  enqueteur                VARCHAR(200),

  producteur_id            UUID REFERENCES producteur(id) ON DELETE SET NULL,
  statut_traitement        statut_traitement_enum NOT NULL DEFAULT 'recue',
  motif_rejet              TEXT,

  lot_ingestion_id         UUID NOT NULL REFERENCES lot_ingestion(id) ON DELETE RESTRICT,
  cree_le                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Compléments issus du formulaire (groupe `intro`) et du traitement M1.
  date_remplissage         DATE,          -- Kobo `date_remplissage`
  doublon_de_id            UUID REFERENCES producteur(id) ON DELETE SET NULL,
  cle_deduplication        VARCHAR(255),  -- RG-M1-03 : sigle|ministere|commune
  traitee_par              UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  traitee_le               TIMESTAMP WITH TIME ZONE,

  -- Un rejet est toujours motivé : c'est la trace opposable au producteur.
  CONSTRAINT chk_soumission_rejet_motive
    CHECK (statut_traitement <> 'rejetee' OR motif_rejet IS NOT NULL),
  CONSTRAINT chk_soumission_doublon_renseigne
    CHECK (statut_traitement <> 'doublon_potentiel' OR doublon_de_id IS NOT NULL)
);

CREATE INDEX idx_soumission_kobo_producteur_id  ON soumission_kobo(producteur_id);
CREATE INDEX idx_soumission_kobo_lot_id         ON soumission_kobo(lot_ingestion_id);
CREATE INDEX idx_soumission_kobo_statut         ON soumission_kobo(statut_traitement);
CREATE INDEX idx_soumission_kobo_kobo_form      ON soumission_kobo(kobo_form_id);
CREATE INDEX idx_soumission_kobo_dedup          ON soumission_kobo(cle_deduplication);
CREATE INDEX idx_soumission_kobo_payload_gin    ON soumission_kobo USING GIN(payload jsonb_path_ops);
-- File d'attente de validation (UC-M4-01) : index partiel sur la quarantaine.
CREATE INDEX idx_soumission_kobo_quarantaine
  ON soumission_kobo(date_soumission_kobo)
  WHERE statut_traitement IN ('recue', 'en_validation', 'doublon_potentiel');

COMMENT ON TABLE soumission_kobo IS
  'Soumissions originales reçues de KoboToolbox. TABLE IMMUABLE : un trigger '
  'rejette tout UPDATE et tout DELETE (RG-M1-04). Elle constitue la chaîne de '
  'preuve depuis la collecte terrain et ne peut être effacée, même après '
  'modification de la fiche qui en est issue.';
COMMENT ON COLUMN soumission_kobo.producteur_id IS
  'Nullable : une soumission en QUARANTAINE n''est pas encore rattachée, et une '
  'soumission REJETÉE ne le sera jamais (SDD §11.3).';

-- -----------------------------------------------------------------------------
-- Journal d'ingestion — SDD §11.3, immuable au même titre que les soumissions.
-- -----------------------------------------------------------------------------
CREATE TABLE journal_ingestion (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_ingestion_id  UUID NOT NULL REFERENCES lot_ingestion(id) ON DELETE RESTRICT,
  soumission_id     UUID REFERENCES soumission_kobo(id) ON DELETE SET NULL,
  horodatage        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  niveau            VARCHAR(10) NOT NULL DEFAULT 'info',
  etape             VARCHAR(60) NOT NULL,
  message           TEXT NOT NULL,
  detail            JSONB,

  CONSTRAINT chk_journal_ingestion_niveau CHECK (niveau IN ('debug', 'info', 'warn', 'error'))
);

CREATE INDEX idx_journal_ingestion_lot        ON journal_ingestion(lot_ingestion_id);
CREATE INDEX idx_journal_ingestion_horodatage ON journal_ingestion(horodatage DESC);
CREATE INDEX idx_journal_ingestion_erreurs    ON journal_ingestion(lot_ingestion_id) WHERE niveau = 'error';

-- -----------------------------------------------------------------------------
-- Séquence des codes producteurs — support de generer_code_producteur().
-- Le compteur est porté par le couple (réseau, ministère) conformément au
-- format CMR-<RÉSEAU>-<MIN>-<STRUCT>-<SEQ> (RG-M1-02).
-- -----------------------------------------------------------------------------
CREATE TABLE compteur_code_producteur (
  reseau_code     VARCHAR(20) NOT NULL,
  ministere_sigle VARCHAR(20) NOT NULL,
  dernier_numero  INTEGER NOT NULL DEFAULT 0,
  updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  PRIMARY KEY (reseau_code, ministere_sigle),
  CONSTRAINT chk_compteur_positif CHECK (dernier_numero >= 0)
);

COMMENT ON TABLE compteur_code_producteur IS
  'Séquences de la partie <SEQ> du code producteur. Une table plutôt qu''une '
  'SEQUENCE PostgreSQL : le compteur est propre à chaque couple réseau/ministère '
  'et doit être transactionnel avec l''insertion de la fiche (SDD §13.3.2).';
