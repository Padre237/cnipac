-- =============================================================================
-- CNIPAC — 22 : ministères et institutions de tutelle
-- Source : TDR §7 (tableau des administrations sectorielles).
-- SRS §12.10 : « ~40 entrées (référentiel SIGIPES / Présidence). Mise à jour à
-- chaque remaniement gouvernemental. »
--
-- À FAIRE VALIDER PAR LES ANC avant la mise en production : le TDR ne fournit
-- pas systématiquement le sigle officiel en regard de l'intitulé complet.
-- Un ministère n'est JAMAIS supprimé de ce référentiel : il est marqué
-- « supprime », « fusionne » ou « renomme », afin que les fiches historiques
-- conservent leur rattachement.
-- =============================================================================
SET search_path TO cnipac, public;

INSERT INTO ministere (code, sigle, libelle_fr, libelle_en, reseau_defaut_id) VALUES
  ('PRC',        'PRC',        'Présidence de la République', 'Presidency of the Republic',                                   (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('SPM',        'SPM',        'Services du Premier Ministre', 'Prime Minister''s Office',                                    (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINAT',      'MINAT',      'Ministère de l''Administration Territoriale', 'Ministry of Territorial Administration',       (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINAS',      'MINAS',      'Ministère des Affaires Sociales', 'Ministry of Social Affairs',                               (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINADER',    'MINADER',    'Ministère de l''Agriculture et du Développement Rural', 'Ministry of Agriculture and Rural Development', (SELECT id FROM reseau_archivistique WHERE code='AGR')),
  ('MINAC',      'MINAC',      'Ministère des Arts et de la Culture', 'Ministry of Arts and Culture',                          (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINCOMMERCE','MINCOMMERCE','Ministère du Commerce', 'Ministry of Trade',                                                  (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINCOM',     'MINCOM',     'Ministère de la Communication', 'Ministry of Communication',                                  (SELECT id FROM reseau_archivistique WHERE code='NUM')),
  ('CONSUPE',    'CONSUPE',    'Ministère chargé du Contrôle Supérieur de l''État', 'Ministry Delegate for Supreme State Audit', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINDDEVEL',  'MINDDEVEL',  'Ministère de la Décentralisation et du Développement Local', 'Ministry of Decentralisation and Local Development', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINDEF',     'MINDEF',     'Ministère de la Défense', 'Ministry of Defence',                                              (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINDCAF',    'MINDCAF',    'Ministère des Domaines, du Cadastre et des Affaires Foncières', 'Ministry of State Property, Surveys and Land Tenure', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINEE',      'MINEE',      'Ministère de l''Eau et de l''Énergie', 'Ministry of Water Resources and Energy',               (SELECT id FROM reseau_archivistique WHERE code='ENE')),
  ('MINEPAT',    'MINEPAT',    'Ministère de l''Économie, de la Planification et de l''Aménagement du Territoire', 'Ministry of Economy, Planning and Regional Development', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINEDUB',    'MINEDUB',    'Ministère de l''Éducation de Base', 'Ministry of Basic Education',                            (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINEPIA',    'MINEPIA',    'Ministère de l''Élevage, des Pêches et des Industries Animales', 'Ministry of Livestock, Fisheries and Animal Industries', (SELECT id FROM reseau_archivistique WHERE code='AGR')),
  ('MINEFOP',    'MINEFOP',    'Ministère de l''Emploi et de la Formation Professionnelle', 'Ministry of Employment and Vocational Training', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINESEC',    'MINESEC',    'Ministère des Enseignements Secondaires', 'Ministry of Secondary Education',                   (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINESUP',    'MINESUP',    'Ministère de l''Enseignement Supérieur', 'Ministry of Higher Education',                       (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINEPDED',   'MINEPDED',   'Ministère de l''Environnement, de la Protection de la Nature et du Développement Durable', 'Ministry of Environment, Nature Protection and Sustainable Development', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINFI',      'MINFI',      'Ministère des Finances', 'Ministry of Finance',                                               (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINFOPRA',   'MINFOPRA',   'Ministère de la Fonction Publique et de la Réforme Administrative', 'Ministry of Public Service and Administrative Reform', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINFOF',     'MINFOF',     'Ministère des Forêts et de la Faune', 'Ministry of Forestry and Wildlife',                     (SELECT id FROM reseau_archivistique WHERE code='FOR')),
  ('MINHDU',     'MINHDU',     'Ministère de l''Habitat et du Développement Urbain', 'Ministry of Housing and Urban Development', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINJEC',     'MINJEC',     'Ministère de la Jeunesse et de l''Éducation Civique', 'Ministry of Youth Affairs and Civic Education', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINJUSTICE', 'MINJUSTICE', 'Ministère de la Justice', 'Ministry of Justice',                                              (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINMAP',     'MINMAP',     'Ministère des Marchés Publics', 'Ministry of Public Contracts',                               (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINIMIDT',   'MINIMIDT',   'Ministère des Mines, de l''Industrie et du Développement Technologique', 'Ministry of Mines, Industry and Technological Development', (SELECT id FROM reseau_archivistique WHERE code='MIN')),
  ('MINPMEESA',  'MINPMEESA',  'Ministère des Petites et Moyennes Entreprises, de l''Économie Sociale et de l''Artisanat', 'Ministry of Small and Medium-Sized Enterprises, Social Economy and Handicrafts', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINPOSTEL',  'MINPOSTEL',  'Ministère des Postes et Télécommunications', 'Ministry of Posts and Telecommunications',      (SELECT id FROM reseau_archivistique WHERE code='NUM')),
  ('MINPROFF',   'MINPROFF',   'Ministère de la Promotion de la Femme et de la Famille', 'Ministry of Women''s Empowerment and the Family', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINRESI',    'MINRESI',    'Ministère de la Recherche Scientifique et de l''Innovation', 'Ministry of Scientific Research and Innovation', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINRA',      'MINRA',      'Ministère chargé des Relations avec les Assemblées', 'Ministry in charge of Relations with the Assemblies', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINREX',     'MINREX',     'Ministère des Relations Extérieures', 'Ministry of External Relations',                       (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINSANTE',   'MINSANTE',   'Ministère de la Santé Publique', 'Ministry of Public Health',                                 (SELECT id FROM reseau_archivistique WHERE code='CHI')),
  ('MINSEP',     'MINSEP',     'Ministère des Sports et de l''Éducation Physique', 'Ministry of Sports and Physical Education', (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINTOUL',    'MINTOUL',    'Ministère du Tourisme et des Loisirs', 'Ministry of Tourism and Leisure',                      (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINTSS',     'MINTSS',     'Ministère du Travail et de la Sécurité Sociale', 'Ministry of Labour and Social Security',     (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINT',       'MINT',       'Ministère des Transports', 'Ministry of Transport',                                           (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('MINTP',      'MINTP',      'Ministère des Travaux Publics', 'Ministry of Public Works',                                   (SELECT id FROM reseau_archivistique WHERE code='CST')),
  ('AUTRE',      'AUTRE',      'Autre institution de tutelle', 'Other supervising institution',                               (SELECT id FROM reseau_archivistique WHERE code='CST'))
ON CONFLICT (code) DO UPDATE
  SET libelle_fr = EXCLUDED.libelle_fr,
      libelle_en = EXCLUDED.libelle_en,
      reseau_defaut_id = EXCLUDED.reseau_defaut_id,
      updated_at = NOW();

COMMENT ON COLUMN ministere.reseau_defaut_id IS
  'Rattachement SND30 par défaut. Support de RG-M2-04 : le réseau d''un '
  'producteur est calculé à partir de son ministère de tutelle et de son statut '
  'administratif. Le réseau CST (9) sert de rattachement aux administrations à '
  'vocation générale, conformément à son intitulé « services professionnels, '
  'scientifiques et techniques ».';
