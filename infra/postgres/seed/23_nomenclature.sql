-- =============================================================================
-- CNIPAC — 23 : libellés des listes contrôlées
--
-- FICHIER GÉNÉRÉ — ne pas modifier à la main.
-- Source : docs/aw2T2qSbuxp3GQdm3wdySZ.xlsx, feuille `choices`.
-- Générateur : scripts/generer-seed-depuis-xlsform.py
--
-- Les VALEURS sont des types ENUM (fichier 01_types_enum.sql) ; cette table
-- ne porte que leurs libellés d'affichage, modifiables par les administrateurs
-- métier sans migration (SRS §12.10, NFR-C8-01).
-- =============================================================================
SET search_path TO cnipac, public;

INSERT INTO nomenclature (liste, code, libelle_fr, ordre_affichage, source) VALUES
  ('type_organisation_enum', 'ministere', 'Administration publique (Ministère)', 1, 'xlsform'),
  ('type_organisation_enum', 'privee', 'Administration privée', 2, 'xlsform'),
  ('type_organisation_enum', 'ctd', 'Service déconcentré (CTD)', 3, 'xlsform'),
  ('type_organisation_enum', 'rattache', 'Service rattaché', 4, 'xlsform'),
  ('type_organisation_enum', 'ep', 'Entreprise ou Établissement public', 5, 'xlsform'),
  ('type_batiment_enum', 'batiment_admin', 'Bâtiment administratif classique', 1, 'xlsform'),
  ('type_batiment_enum', 'entrepot_archives', 'Entrepôt / magasin dédié aux archives', 2, 'xlsform'),
  ('type_batiment_enum', 'bureau_local', 'Bureau ou local non spécialisé', 3, 'xlsform'),
  ('type_batiment_enum', 'local_provisoire', 'Local de fortune / provisoire', 4, 'xlsform'),
  ('type_batiment_enum', 'autre', 'Autre (préciser)', 5, 'xlsform'),
  ('type_personnel_enum', 'non_arch', 'Non Archivistes', 1, 'xlsform'),
  ('type_personnel_enum', 'arch_ass', 'Archivistes assermentés', 2, 'xlsform'),
  ('type_personnel_enum', 'arch_non_ass', 'Archivistes non assermentés', 3, 'xlsform'),
  ('type_personnel_enum', 'informaticien', 'Informaticiens', 4, 'xlsform'),
  ('type_personnel_enum', 'autres', 'Autres', 5, 'xlsform'),
  ('support_archive_enum', 'papier', 'Papier', 1, 'xlsform'),
  ('support_archive_enum', 'numerique', 'Support numérique', 2, 'xlsform'),
  ('support_archive_enum', 'audiovisuel', 'Support audiovisuel', 3, 'xlsform'),
  ('support_archive_enum', 'bande_magnetique', 'Bande magnétique', 4, 'xlsform'),
  ('support_archive_enum', 'plan', 'Plan', 5, 'xlsform'),
  ('support_archive_enum', 'carte', 'Carte', 6, 'xlsform'),
  ('support_archive_enum', 'autres', 'Autres', 7, 'xlsform'),
  ('materiau_rayonnage_enum', 'bois', 'Bois', 1, 'xlsform'),
  ('materiau_rayonnage_enum', 'metal', 'Métal', 2, 'xlsform'),
  ('mobilite_rayonnage_enum', 'fixe', 'Fixe', 1, 'xlsform'),
  ('mobilite_rayonnage_enum', 'mobile', 'Mobile', 2, 'xlsform'),
  ('type_boite_enum', 'simple', 'Simple', 1, 'xlsform'),
  ('type_boite_enum', 'ignifuge', 'Ignifuge', 2, 'xlsform'),
  ('source_energie_enum', 'energie_electrique', 'Énergie électrique', 1, 'xlsform'),
  ('source_energie_enum', 'generateur', 'Générateur', 2, 'xlsform'),
  ('source_energie_enum', 'energie_solaire', 'Énergie solaire', 3, 'xlsform'),
  ('sys_refroidissement_enum', 'air_conditionne', 'Air conditionné', 1, 'xlsform'),
  ('sys_refroidissement_enum', 'ecologique_eau', 'Écologique (eau)', 2, 'xlsform'),
  ('typologie_logiciel_enum', 'gratuit', 'Gratuit', 1, 'xlsform'),
  ('typologie_logiciel_enum', 'open_source', 'Open Source', 2, 'xlsform'),
  ('typologie_logiciel_enum', 'proprietaire', 'Propriétaire', 3, 'xlsform'),
  ('format_fichier_enum', 'pdf', 'PDF', 1, 'xlsform'),
  ('format_fichier_enum', 'doc_docx', 'DOC/DOCX', 2, 'xlsform'),
  ('format_fichier_enum', 'xls_xlsx', 'XLS/XLSX', 3, 'xlsform'),
  ('format_fichier_enum', 'jpg_png_tif', 'JPG/PNG/TIF', 4, 'xlsform'),
  ('format_fichier_enum', 'mp3', 'MP3', 5, 'xlsform'),
  ('format_fichier_enum', 'mp4', 'MP4', 6, 'xlsform'),
  ('format_fichier_enum', 'autres', 'Autres', 7, 'xlsform'),
  ('etat_materiel_enum', 'bon_etat', 'Bon état général', 1, 'xlsform'),
  ('etat_materiel_enum', 'poussiereux', 'Poussiéreux / encrassés', 2, 'xlsform'),
  ('etat_materiel_enum', 'jaunissement', 'Jaunissement / fragilisation du papier', 3, 'xlsform'),
  ('etat_materiel_enum', 'moisissures', 'Moisissures / traces d''humidité', 4, 'xlsform'),
  ('etat_materiel_enum', 'insectes', 'Infestation d''insectes (termites, etc.)', 5, 'xlsform'),
  ('etat_materiel_enum', 'dechirures', 'Déchirures / pertes importantes', 6, 'xlsform'),
  ('etat_materiel_enum', 'autre', 'Autre (préciser)', 7, 'xlsform'),
  ('dispositif_securite_enum', 'videosurveillance', 'Vidéosurveillance', 1, 'xlsform'),
  ('dispositif_securite_enum', 'biometrie', 'Biométrie', 2, 'xlsform'),
  ('dispositif_securite_enum', 'extincteurs', 'Extincteurs présents et à jour', 3, 'xlsform'),
  ('dispositif_securite_enum', 'issues_secours', 'Issues de secours / évacuation', 4, 'xlsform'),
  ('dispositif_securite_enum', 'detecteurs_fumee', 'Détecteurs de fumée', 5, 'xlsform'),
  ('dispositif_securite_enum', 'agents_securite', 'Agents de sécurité', 6, 'xlsform'),
  ('dispositif_securite_enum', 'extinction_auto', 'Système d''extinction automatique', 7, 'xlsform'),
  ('dispositif_securite_enum', 'aucun', 'Aucun dispositif spécifique', 8, 'xlsform'),
  ('risque_environnemental_enum', 'inondable', 'Zone inondable / proximité cours d''eau', 1, 'xlsform'),
  ('risque_environnemental_enum', 'infiltrations', 'Infiltrations d''eau / toiture défectueuse', 2, 'xlsform'),
  ('risque_environnemental_enum', 'humidite', 'Forte humidité ambiante régulière', 3, 'xlsform'),
  ('risque_environnemental_enum', 'soleil_chaleur', 'Exposition directe au soleil / chaleur excessive', 4, 'xlsform'),
  ('risque_environnemental_enum', 'autre', 'Autre risque (préciser)', 5, 'xlsform'),
  ('outil_gestion_enum', 'politique_archivage', 'Politique d''archivage', 1, 'xlsform'),
  ('outil_gestion_enum', 'plan_classement', 'Plan de classement', 2, 'xlsform'),
  ('outil_gestion_enum', 'manuel_procedures', 'Manuel de procédures', 3, 'xlsform'),
  ('outil_gestion_enum', 'calendrier_conservation', 'Calendrier de conservation/élimination', 4, 'xlsform'),
  ('niveau_validation_enum', 'archives_nationales', 'Archives Nationales du Cameroun', 1, 'xlsform'),
  ('niveau_validation_enum', 'responsable_structure', 'Responsable de la structure', 2, 'xlsform'),
  ('niveau_validation_enum', 'autres', 'Autres', 3, 'xlsform'),
  ('instrument_recherche_enum', 'inventaire_papier', 'Inventaire(s) papier', 1, 'xlsform'),
  ('instrument_recherche_enum', 'bordereaux_versement', 'Bordereaux de versement', 2, 'xlsform'),
  ('instrument_recherche_enum', 'base_donnees', 'Base de données / tableur', 3, 'xlsform'),
  ('instrument_recherche_enum', 'aucun', 'Aucun instrument formel', 4, 'xlsform'),
  ('accessibilite_site_enum', 'gros_tonnage', 'Accessible aux camions de gros tonnage (> 3,5 t)', 1, 'xlsform'),
  ('accessibilite_site_enum', 'camionnette', 'Accessible aux camionnettes / petits utilitaires seulement', 2, 'xlsform'),
  ('accessibilite_site_enum', 'difficile', 'Accès difficile / piéton uniquement', 3, 'xlsform'),
  ('equipement_manutention_enum', 'ascenseur', 'Ascenseur / monte-charge', 1, 'xlsform'),
  ('equipement_manutention_enum', 'monte_escalier', 'Monte-escalier', 2, 'xlsform'),
  ('equipement_manutention_enum', 'rampe', 'Rampe d''accès', 3, 'xlsform'),
  ('equipement_manutention_enum', 'chariots', 'Chariots', 4, 'xlsform'),
  ('equipement_manutention_enum', 'aucun', 'Aucun équipement', 5, 'xlsform'),
  ('conditionnement_enum', 'boites_standards', 'Majoritairement en boîtes d''archives standards', 1, 'xlsform'),
  ('conditionnement_enum', 'dossiers_suspendus', 'En dossiers suspendus / classeurs', 2, 'xlsform'),
  ('conditionnement_enum', 'en_vrac', 'En vrac / liasses', 3, 'xlsform'),
  ('conditionnement_enum', 'melange', 'Mélange', 4, 'xlsform')
ON CONFLICT (liste, code) DO UPDATE
  SET libelle_fr = EXCLUDED.libelle_fr,
      ordre_affichage = EXCLUDED.ordre_affichage,
      updated_at = NOW();

-- Contrôle : chaque libellé doit correspondre à une valeur réelle de son ENUM.
DO $$
DECLARE r RECORD; v_existe BOOLEAN;
BEGIN
  FOR r IN SELECT DISTINCT liste, code FROM nomenclature WHERE source = 'xlsform' LOOP
    EXECUTE format('SELECT $1 = ANY(enum_range(NULL::cnipac.%I)::text[])', r.liste)
      INTO v_existe USING r.code;
    IF NOT v_existe THEN
      RAISE EXCEPTION 'Le code « % » ne fait pas partie du type %', r.code, r.liste;
    END IF;
  END LOOP;
END $$;
