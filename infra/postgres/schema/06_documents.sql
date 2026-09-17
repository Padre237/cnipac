-- =============================================================================
-- CNIPAC — 06 : pièces jointes (domaine DOM-DOC)
-- Source : SDD V4.0 §11.7. Les fichiers résident sur le système de fichiers
-- chiffré ; la base ne conserve que la métadonnée.
-- =============================================================================
SET search_path TO cnipac, public;

CREATE TABLE piece_jointe (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producteur_id       UUID REFERENCES producteur(id) ON DELETE CASCADE,

  nom_original        VARCHAR(255) NOT NULL,
  type_mime           VARCHAR(120) NOT NULL,
  taille_octets       BIGINT NOT NULL,

  -- SDD §11.7 : « le chemin_stockage est relatif (jamais absolu) pour faciliter
  -- la portabilité entre environnements ».
  chemin_stockage     VARCHAR(500) NOT NULL,
  hash_sha256         CHAR(64) NOT NULL,
  cle_chiffrement_ref VARCHAR(80),

  -- SDD §11.7 : « le résultat de l'analyse antivirus est consigné avant tout
  -- accès en lecture ».
  scan_av_resultat    scan_av_enum NOT NULL DEFAULT 'en_cours',
  scan_av_le          TIMESTAMP WITH TIME ZONE,
  scan_av_detail      TEXT,

  categorie           VARCHAR(60),   -- arrete, organigramme, photo_local, lettre_designation
  televerse_par       UUID REFERENCES utilisateur(id) ON DELETE SET NULL,
  televerse_le        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMP WITH TIME ZONE,

  CONSTRAINT chk_piece_jointe_chemin_relatif CHECK (chemin_stockage !~ '^/'),
  CONSTRAINT chk_piece_jointe_hash_hex CHECK (hash_sha256 ~ '^[0-9a-f]{64}$'),
  -- SRS §12.1 : pièces jointes de 50 Mo au maximum (SDD §26.3, client_max_body_size).
  CONSTRAINT chk_piece_jointe_taille CHECK (taille_octets > 0 AND taille_octets <= 52428800),
  CONSTRAINT chk_piece_jointe_categorie CHECK (
    categorie IS NULL OR categorie IN
    ('arrete', 'organigramme', 'photo_local', 'lettre_designation', 'plan_classement',
     'calendrier_conservation', 'visa_elimination', 'autre')
  ),
  -- Un scan terminé porte nécessairement son horodatage.
  CONSTRAINT chk_piece_jointe_scan_horodate
    CHECK (scan_av_resultat = 'en_cours' OR scan_av_le IS NOT NULL)
);

CREATE INDEX idx_piece_jointe_producteur ON piece_jointe(producteur_id);
CREATE INDEX idx_piece_jointe_hash       ON piece_jointe(hash_sha256);
CREATE INDEX idx_piece_jointe_categorie  ON piece_jointe(categorie);
-- Les pièces non saines ne doivent jamais être servies : index dédié pour la
-- supervision et le blocage en lecture.
CREATE INDEX idx_piece_jointe_scan_non_propre
  ON piece_jointe(scan_av_resultat) WHERE scan_av_resultat <> 'propre';

COMMENT ON TABLE piece_jointe IS
  'Métadonnées des pièces documentaires (arrêtés, organigrammes, photos du local '
  'saisies par Kobo V.2 `photo_preuve`). Le fichier lui-même est stocké chiffré '
  'sur le système de fichiers (SDD §11.7 et §12.13.3).';
COMMENT ON COLUMN piece_jointe.hash_sha256 IS
  'Empreinte du fichier, vérifiée à chaque lecture : détecte toute corruption '
  'du stockage. Sert aussi à la déduplication.';
