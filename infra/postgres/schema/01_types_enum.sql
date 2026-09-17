-- =============================================================================
-- CNIPAC — 01 : types ENUM
--
-- Bloc A : les 13 types du SDD V4.0 §12.2, reproduits À LA LETTRE.
-- Bloc B : les listes contrôlées du formulaire KoboToolbox
--          (docs/aw2T2qSbuxp3GQdm3wdySZ.xlsx, feuille `choices`), qui relèvent
--          de l'Annexe A annoncée par le SDD §12 et non fournie.
--
-- Convention SDD §12.1 : préfixe par catégorie + suffixe `_enum`.
-- =============================================================================
SET search_path TO cnipac, public;

-- -----------------------------------------------------------------------------
-- BLOC A — types du SDD §12.2 (transcription littérale)
-- -----------------------------------------------------------------------------

-- Statut administratif d'un producteur (cf. SRS §12.10)
CREATE TYPE statut_admin_enum AS ENUM (
  'public', 'parapublic', 'semi_public', 'prive_delegataire'
);

-- Type d'entité productrice (cf. SRS §12.10)
CREATE TYPE type_entite_enum AS ENUM (
  'ministere_central', 'service_deconcentre', 'etablissement_public',
  'entreprise_publique', 'ctd', 'universite', 'autre'
);

-- Cycle de vie d'une fiche producteur (cf. SRS §11.1 — automate RG-M1-05)
CREATE TYPE statut_fiche_enum AS ENUM (
  'nouvelle', 'quarantaine', 'validee', 'editee', 'archivee', 'rejetee'
);

-- Statut de traitement d'une soumission Kobo
CREATE TYPE statut_traitement_enum AS ENUM (
  'recue', 'en_validation', 'validee', 'rejetee', 'doublon_potentiel'
);

-- Niveau d'unité administrative
CREATE TYPE niveau_unite_admin_enum AS ENUM (
  'national', 'region', 'departement', 'commune', 'arrondissement'
);

-- Statut d'un compte utilisateur
CREATE TYPE statut_compte_enum AS ENUM (
  'actif', 'verrouille_temporairement', 'desactive', 'expire'
);

-- Statut d'un point focal (R-05)
CREATE TYPE statut_point_focal_enum AS ENUM (
  'designe_en_attente', 'actif', 'dormant', 'desactive'
);

-- Statut d'une proposition de mise à jour
-- NOTE DE CONFORMITÉ : la valeur 'accepteee' comporte trois « e ». Elle est
-- reproduite telle qu'elle figure au SDD §12.2. Il s'agit très probablement
-- d'une coquille du document : toute requête applicative devra l'employer à
-- l'identique. Correction proposée au COPIL — voir docs/ANOMALIES-DOCUMENTAIRES.md.
CREATE TYPE statut_proposition_enum AS ENUM (
  'en_attente', 'accepteee', 'refusee', 'complement_demande', 'archivee_non_traitee'
);

-- Module fonctionnel (M1 à M7)
CREATE TYPE module_enum AS ENUM ('M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7');

-- Action de permission (cf. SRS §6 RBAC)
CREATE TYPE action_enum AS ENUM (
  'lire', 'creer', 'modifier', 'supprimer', 'valider', 'exporter', 'administrer'
);

-- Périmètre d'application d'une permission
CREATE TYPE perimetre_enum AS ENUM ('global', 'ma_structure', 'mon_reseau', 'ma_region');

-- Résultat d'un scan antivirus sur une pièce jointe
CREATE TYPE scan_av_enum AS ENUM ('en_cours', 'propre', 'suspect', 'infecte', 'erreur_scan');

-- -----------------------------------------------------------------------------
-- BLOC B — listes contrôlées du formulaire KoboToolbox
-- Chaque type reprend EXACTEMENT les codes de la feuille `choices`, dans l'ordre
-- du formulaire. Le libellé français figure en commentaire.
-- -----------------------------------------------------------------------------

-- choices.type_organisation — Kobo I.2 « Type d'organisation »
-- Distinct de type_entite_enum (SRS §12.10) : le formulaire terrain propose une
-- nomenclature plus courte. La correspondance est assurée par la fonction
-- cnipac.mapper_type_organisation() (fichier 10_fonctions.sql).
CREATE TYPE type_organisation_enum AS ENUM (
  'ministere',   -- Administration publique (Ministère)
  'privee',      -- Administration privée
  'ctd',         -- Service déconcentré (CTD)
  'rattache',    -- Service rattaché
  'ep'           -- Entreprise ou Établissement public
);

-- choices.type_batiment — Kobo III.4
CREATE TYPE type_batiment_enum AS ENUM (
  'batiment_admin',      -- Bâtiment administratif classique
  'entrepot_archives',   -- Entrepôt / magasin dédié aux archives
  'bureau_local',        -- Bureau ou local non spécialisé
  'local_provisoire',    -- Local de fortune / provisoire
  'autre'                -- Autre (préciser)
);

-- choices.types_personnel — Kobo III.2 (sélection multiple)
CREATE TYPE type_personnel_enum AS ENUM (
  'non_arch',       -- Non Archivistes
  'arch_ass',       -- Archivistes assermentés
  'arch_non_ass',   -- Archivistes non assermentés
  'informaticien',  -- Informaticiens
  'autres'          -- Autres
);

-- choices.supports_physiques — Kobo IV.1 (sélection multiple)
CREATE TYPE support_archive_enum AS ENUM (
  'papier', 'numerique', 'audiovisuel', 'bande_magnetique', 'plan', 'carte', 'autres'
);

-- choices.materiau_rayonnage — Kobo IV.3
CREATE TYPE materiau_rayonnage_enum AS ENUM ('bois', 'metal');

-- choices.mobilite_rayonnage — Kobo IV.3
CREATE TYPE mobilite_rayonnage_enum AS ENUM ('fixe', 'mobile');

-- choices.type_boites — Kobo IV.3 (sélection multiple)
CREATE TYPE type_boite_enum AS ENUM ('simple', 'ignifuge');

-- choices.sources_energie — Kobo IV.4 (sélection multiple)
CREATE TYPE source_energie_enum AS ENUM ('energie_electrique', 'generateur', 'energie_solaire');

-- choices.sys_refroidissement — Kobo IV.4 (sélection multiple)
CREATE TYPE sys_refroidissement_enum AS ENUM ('air_conditionne', 'ecologique_eau');

-- choices.typologie_logiciel — Kobo IV.4 (sélection multiple)
CREATE TYPE typologie_logiciel_enum AS ENUM ('gratuit', 'open_source', 'proprietaire');

-- choices.formats_fichiers — Kobo IV.4.1 (sélection multiple)
CREATE TYPE format_fichier_enum AS ENUM (
  'pdf', 'doc_docx', 'xls_xlsx', 'jpg_png_tif', 'mp3', 'mp4', 'autres'
);

-- choices.etat_materiel — Kobo V.1 (sélection multiple)
CREATE TYPE etat_materiel_enum AS ENUM (
  'bon_etat',      -- Bon état général
  'poussiereux',   -- Poussiéreux / encrassés
  'jaunissement',  -- Jaunissement / fragilisation du papier
  'moisissures',   -- Moisissures / traces d'humidité
  'insectes',      -- Infestation d'insectes (termites, etc.)
  'dechirures',    -- Déchirures / pertes importantes
  'autre'          -- Autre (préciser)
);

-- choices.dispositifs_securite — Kobo V.3 (sélection multiple)
CREATE TYPE dispositif_securite_enum AS ENUM (
  'videosurveillance', 'biometrie', 'extincteurs', 'issues_secours',
  'detecteurs_fumee', 'agents_securite', 'extinction_auto', 'aucun'
);

-- choices.risques_env — Kobo V.4 (sélection multiple)
CREATE TYPE risque_environnemental_enum AS ENUM (
  'inondable',       -- Zone inondable / proximité cours d'eau
  'infiltrations',   -- Infiltrations d'eau / toiture défectueuse
  'humidite',        -- Forte humidité ambiante régulière
  'soleil_chaleur',  -- Exposition directe au soleil / chaleur excessive
  'autre'            -- Autre risque (préciser)
);

-- choices.outils_gestion — Kobo VI.1 (sélection multiple)
-- Ces quatre valeurs alimentent directement l'indice de maturité RG-M3-01.
CREATE TYPE outil_gestion_enum AS ENUM (
  'politique_archivage', 'plan_classement', 'manuel_procedures', 'calendrier_conservation'
);

-- choices.niveau_validation — Kobo VI.2
CREATE TYPE niveau_validation_enum AS ENUM (
  'archives_nationales', 'responsable_structure', 'autres'
);

-- choices.instruments_recherche — Kobo VI.3 (sélection multiple)
CREATE TYPE instrument_recherche_enum AS ENUM (
  'inventaire_papier', 'bordereaux_versement', 'base_donnees', 'aucun'
);

-- choices.accessibilite_site — Kobo VII.1
CREATE TYPE accessibilite_site_enum AS ENUM (
  'gros_tonnage',  -- Accessible aux camions de gros tonnage (> 3,5 t)
  'camionnette',   -- Accessible aux camionnettes / petits utilitaires seulement
  'difficile'      -- Accès difficile / piéton uniquement
);

-- choices.equip_manutention — Kobo VII.2 (sélection multiple)
CREATE TYPE equipement_manutention_enum AS ENUM (
  'ascenseur', 'monte_escalier', 'rampe', 'chariots', 'aucun'
);

-- choices.conditionnement_archives — Kobo VII.3 (sélection multiple)
CREATE TYPE conditionnement_enum AS ENUM (
  'boites_standards',    -- Majoritairement en boîtes d'archives standards
  'dossiers_suspendus',  -- En dossiers suspendus / classeurs
  'en_vrac',             -- En vrac / liasses
  'melange'              -- Mélange
);

-- Source d'alimentation d'une fiche (traçabilité de l'ingestion, ADR M1)
CREATE TYPE source_ingestion_enum AS ENUM ('kobo', 'import_csv', 'saisie_manuelle', 'migration');

-- Statut d'un lot d'ingestion (M1)
CREATE TYPE statut_lot_enum AS ENUM ('en_cours', 'termine', 'termine_avec_erreurs', 'echoue');
