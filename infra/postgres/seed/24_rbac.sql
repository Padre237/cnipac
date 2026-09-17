-- =============================================================================
-- CNIPAC — 24 : rôles et permissions RBAC
-- Source : SRS V2.0 §6.2 (catalogue des 8 rôles), §6.3 (permissions par module),
--          §6.4 (matrice rôle × permission), §6.5.3 (MFA).
-- AC-P1-06 : « le RBAC est opérationnel sur 8 rôles ».
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- Les 8 rôles — SRS §6.2
-- -----------------------------------------------------------------------------
INSERT INTO role (code, libelle_fr, libelle_en, description_fr, mfa_obligatoire, ordre_affichage) VALUES
  ('R-01', 'Super-administrateur système', 'System super-administrator',
   'Administration technique complète : comptes, paramètres, restauration, journaux.', TRUE, 1),
  ('R-02', 'Administrateur métier ANC', 'ANC business administrator',
   'Administration fonctionnelle : référentiels, comptes points focaux, supervision métier.', FALSE, 2),
  ('R-03', 'Archiviste validateur', 'Validating archivist',
   'Validation des soumissions en quarantaine, édition des fiches, traitement du crowdsourcing.', FALSE, 3),
  ('R-04', 'Archiviste consultation', 'Read-only archivist',
   'Consultation complète du référentiel, sans droit de modification.', FALSE, 4),
  ('R-05', 'Point focal archives', 'Archives focal point',
   'Correspondant archives d''une structure (art. 19 Loi 2024/001). Périmètre strictement limité à SA structure.', FALSE, 5),
  ('R-06', 'Décideur / Inspecteur archivistique', 'Decision-maker / Archives inspector',
   'Consultation des tableaux de bord stratégiques et des rapports nationaux.', FALSE, 6),
  ('R-07', 'Agent terrain', 'Field agent',
   'Consultation de l''avancement de la collecte sur son périmètre.', FALSE, 7),
  ('R-08', 'Chercheur / API publique', 'Researcher / Public API',
   'Accès en lecture aux données publiques et à l''API ouverte.', FALSE, 8)
ON CONFLICT (code) DO UPDATE
  SET libelle_fr = EXCLUDED.libelle_fr, libelle_en = EXCLUDED.libelle_en,
      mfa_obligatoire = EXCLUDED.mfa_obligatoire, updated_at = NOW();

DO $$
DECLARE v_nb INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_nb FROM role;
  IF v_nb <> 8 THEN
    RAISE EXCEPTION 'Le catalogue RBAC doit compter exactement 8 rôles (AC-P1-06), or il en compte %', v_nb;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- Permissions élémentaires — SRS §6.3, nomenclature P-Mx-yy
-- -----------------------------------------------------------------------------
INSERT INTO permission (code, module, action, ressource, perimetre, libelle_fr) VALUES
  -- M1 — Synchronisation et ingestion
  ('P-M1-01', 'M1', 'administrer', 'connexion_kobo',   'global', 'Configurer la connexion KoboToolbox'),
  ('P-M1-02', 'M1', 'creer',       'lot_ingestion',    'global', 'Déclencher une synchronisation'),
  ('P-M1-03', 'M1', 'creer',       'import_fichier',   'global', 'Importer un fichier CSV ou Excel'),
  ('P-M1-04', 'M1', 'lire',        'journal_ingestion','global', 'Consulter le journal d''ingestion'),
  ('P-M1-05', 'M1', 'lire',        'quarantaine',      'global', 'Consulter la zone de quarantaine'),

  -- M2 — Visualisation cartographique
  ('P-M2-01', 'M2', 'lire',        'carte_publique',   'global', 'Consulter la carte publique'),
  ('P-M2-02', 'M2', 'lire',        'fiche_publique',   'global', 'Consulter une fiche synthétique publique'),
  ('P-M2-03', 'M2', 'exporter',    'vue_carte',        'global', 'Exporter la vue cartographique'),
  ('P-M2-04', 'M2', 'lire',        'donnees_sensibles','global', 'Voir les champs non publics d''une fiche'),

  -- M3 — Tableaux de bord
  ('P-M3-01', 'M3', 'lire',        'tdb_national',     'global', 'Consulter le tableau de bord national'),
  ('P-M3-02', 'M3', 'lire',        'tdb_strategique',  'global', 'Consulter le tableau de bord stratégique'),
  ('P-M3-03', 'M3', 'exporter',    'tdb',              'global', 'Exporter un tableau de bord'),
  ('P-M3-04', 'M3', 'lire',        'tdb_regional',     'ma_region', 'Consulter les indicateurs de sa région'),
  ('P-M3-05', 'M3', 'creer',       'rapport_annuel',   'global', 'Générer le rapport national annuel'),

  -- M4 — Gestion des producteurs
  ('P-M4-01', 'M4', 'lire',        'file_validation',  'global', 'Consulter la file d''attente de validation'),
  ('P-M4-02', 'M4', 'valider',     'soumission',       'global', 'Valider une soumission'),
  ('P-M4-03', 'M4', 'valider',     'rejet_soumission', 'global', 'Rejeter une soumission'),
  ('P-M4-04', 'M4', 'modifier',    'producteur',       'global', 'Modifier une fiche validée'),
  ('P-M4-05', 'M4', 'lire',        'producteur',       'global', 'Consulter une fiche détaillée'),
  ('P-M4-06', 'M4', 'lire',        'historique',       'global', 'Consulter l''historique des versions'),
  ('P-M4-07', 'M4', 'modifier',    'restauration_version', 'global', 'Restaurer une version antérieure'),
  ('P-M4-08', 'M4', 'supprimer',   'archivage_fiche',  'global', 'Archiver logiquement une fiche'),
  ('P-M4-09', 'M4', 'modifier',    'fusion_doublons',  'global', 'Fusionner deux fiches doublons'),
  ('P-M4-10', 'M4', 'creer',       'piece_jointe',     'global', 'Téléverser une pièce jointe'),
  ('P-M4-11', 'M4', 'lire',        'ma_fiche',         'ma_structure', 'Consulter la fiche de sa structure'),

  -- M5 — Crowdsourcing
  ('P-M5-01', 'M5', 'creer',       'proposition',      'ma_structure', 'Soumettre une proposition de modification'),
  ('P-M5-02', 'M5', 'lire',        'mes_propositions', 'ma_structure', 'Suivre ses propositions'),
  ('P-M5-03', 'M5', 'lire',        'propositions',     'global', 'Consulter toutes les propositions'),
  ('P-M5-04', 'M5', 'valider',     'proposition',      'global', 'Accepter ou refuser une proposition'),
  ('P-M5-05', 'M5', 'administrer', 'point_focal',      'global', 'Gérer les comptes points focaux'),

  -- M6 — Administration, sécurité, RBAC
  ('P-M6-01', 'M6', 'creer',       'utilisateur',      'global', 'Créer un compte utilisateur'),
  ('P-M6-02', 'M6', 'modifier',    'utilisateur',      'global', 'Modifier un compte utilisateur'),
  ('P-M6-03', 'M6', 'supprimer',   'utilisateur',      'global', 'Désactiver un compte utilisateur'),
  ('P-M6-04', 'M6', 'administrer', 'role',             'global', 'Attribuer ou révoquer un rôle'),
  ('P-M6-05', 'M6', 'lire',        'journal_audit',    'global', 'Consulter les journaux d''audit'),
  ('P-M6-06', 'M6', 'administrer', 'parametre_systeme','global', 'Configurer les paramètres techniques'),
  ('P-M6-07', 'M6', 'administrer', 'restauration',     'global', 'Restaurer depuis une sauvegarde'),
  ('P-M6-08', 'M6', 'administrer', 'referentiel',      'global', 'Administrer les référentiels métier'),
  ('P-M6-09', 'M6', 'lire',        'supervision',      'global', 'Consulter la supervision technique'),

  -- M7 — API et interopérabilité
  ('P-M7-01', 'M7', 'lire',        'api_publique',     'global', 'Consommer l''API publique anonyme'),
  ('P-M7-02', 'M7', 'lire',        'api_chercheur',    'global', 'Consommer l''API chercheur authentifiée'),
  ('P-M7-03', 'M7', 'exporter',    'dump_volumetrique','global', 'Exporter un dump volumétrique'),
  ('P-M7-04', 'M7', 'exporter',    'eac_cpf',          'global', 'Exporter une notice EAC-CPF'),
  ('P-M7-05', 'M7', 'administrer', 'cle_api',          'global', 'Gérer les clés d''API')
ON CONFLICT (code) DO UPDATE
  SET libelle_fr = EXCLUDED.libelle_fr;

-- -----------------------------------------------------------------------------
-- Matrice rôle × permission — SRS §6.4
-- Le principe de moindre privilège gouverne cette matrice : chaque rôle ne
-- reçoit que ce dont il a besoin. R-05 (point focal) est cantonné à SA structure.
-- -----------------------------------------------------------------------------
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p WHERE
  -- R-01 Super-administrateur : toutes les permissions.
  (r.code = 'R-01')

  -- R-02 Administrateur métier ANC : tout le métier, hors administration technique.
  OR (r.code = 'R-02' AND p.code NOT IN ('P-M6-06','P-M6-07','P-M6-09'))

  -- R-03 Archiviste validateur : ingestion, validation, édition, crowdsourcing.
  OR (r.code = 'R-03' AND p.code IN (
      'P-M1-02','P-M1-03','P-M1-04','P-M1-05',
      'P-M2-01','P-M2-02','P-M2-03','P-M2-04',
      'P-M3-01','P-M3-03',
      'P-M4-01','P-M4-02','P-M4-03','P-M4-04','P-M4-05','P-M4-06','P-M4-07','P-M4-08','P-M4-09','P-M4-10',
      'P-M5-03','P-M5-04',
      'P-M7-04'))

  -- R-04 Archiviste consultation : lecture seule, données sensibles comprises.
  OR (r.code = 'R-04' AND p.code IN (
      'P-M1-04','P-M1-05','P-M2-01','P-M2-02','P-M2-03','P-M2-04',
      'P-M3-01','P-M3-03','P-M4-05','P-M4-06','P-M5-03'))

  -- R-05 Point focal : sa structure uniquement. Aucune permission « global »
  -- sur les données d'autrui — c'est le cloisonnement exigé par RG-M5-01.
  OR (r.code = 'R-05' AND p.code IN (
      'P-M2-01','P-M2-02','P-M4-11','P-M5-01','P-M5-02'))

  -- R-06 Décideur / Inspecteur : tableaux de bord et rapports.
  OR (r.code = 'R-06' AND p.code IN (
      'P-M2-01','P-M2-02','P-M2-03','P-M3-01','P-M3-02','P-M3-03','P-M3-05','P-M4-05'))

  -- R-07 Agent terrain : avancement de la collecte sur son périmètre.
  OR (r.code = 'R-07' AND p.code IN (
      'P-M1-05','P-M2-01','P-M2-02','P-M3-04'))

  -- R-08 Chercheur / API publique : données publiques uniquement.
  OR (r.code = 'R-08' AND p.code IN (
      'P-M2-01','P-M2-02','P-M2-03','P-M3-01','P-M7-01','P-M7-02','P-M7-03'))
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Contrôles d'intégrité du modèle de sécurité.
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_nb INTEGER;
BEGIN
  -- NFR-C4-01 : un point focal ne doit jamais accéder aux données d'une autre
  -- structure. Aucune de ses permissions ne peut donc être de portée globale
  -- sur des données de producteur.
  SELECT COUNT(*) INTO v_nb
  FROM role_permission rp
  JOIN role r ON r.id = rp.role_id
  JOIN permission p ON p.id = rp.permission_id
  WHERE r.code = 'R-05'
    AND p.perimetre = 'global'
    AND p.ressource IN ('producteur','donnees_sensibles','file_validation','propositions','journal_audit');
  IF v_nb > 0 THEN
    RAISE EXCEPTION 'Le rôle R-05 (point focal) dispose de % permission(s) globales sur des données de producteur : violation de RG-M5-01 et NFR-C4-01', v_nb;
  END IF;

  -- Le chercheur ne doit jamais voir de donnée sensible.
  SELECT COUNT(*) INTO v_nb
  FROM role_permission rp
  JOIN role r ON r.id = rp.role_id
  JOIN permission p ON p.id = rp.permission_id
  WHERE r.code = 'R-08' AND p.ressource = 'donnees_sensibles';
  IF v_nb > 0 THEN
    RAISE EXCEPTION 'Le rôle R-08 (chercheur) accède aux données sensibles : violation de NFR-C4-01';
  END IF;

  -- Tout rôle doit disposer d'au moins une permission.
  SELECT COUNT(*) INTO v_nb
  FROM role r WHERE NOT EXISTS (SELECT 1 FROM role_permission rp WHERE rp.role_id = r.id);
  IF v_nb > 0 THEN
    RAISE EXCEPTION '% rôle(s) sans aucune permission', v_nb;
  END IF;
END $$;
