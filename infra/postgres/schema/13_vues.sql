-- =============================================================================
-- CNIPAC — 13 : vues et vues matérialisées
-- Sources : SDD V4.0 §12.10 (mv_kpi_national et mv_repartition_par_reseau,
--           transcription LITTÉRALE), SRS V2.0 §5.3 (module M3),
--           RG-M2-01, RG-M2-02, RG-M3-02, RG-M3-03, NFR-C4-01.
-- =============================================================================
SET search_path TO cnipac, public;

-- #############################################################################
-- VUE PUBLIQUE — le garde-fou de la confidentialité
--
-- RG-M2-02 : « la carte publique non authentifiée n'affiche que les champs non
-- sensibles ». NFR-C4-01 : « les données nominatives NE DOIVENT PAS être
-- exposées publiquement dans la carte ou l'API non authentifiée ».
--
-- Cette vue est l'UNIQUE source autorisée de l'API publique et de la carte
-- anonyme. Elle ne contient aucune donnée nominative par construction : une
-- fuite exigerait de modifier cette définition, donc une migration revue.
-- #############################################################################
CREATE VIEW v_producteur_public AS
SELECT
  p.code_producteur,              -- identifiant public pérenne (FR-M7-04, RG-M1-02)
  p.nom_officiel,
  p.sigle,
  p.noms_paralleles,
  p.type_entite,
  p.statut_admin,
  p.date_creation,
  p.mission,
  ST_Y(p.geom) AS latitude,
  ST_X(p.geom) AS longitude,
  r.code        AS reseau_code,
  r.libelle_fr  AS reseau_libelle_fr,
  r.libelle_en  AS reseau_libelle_en,
  m.sigle       AS ministere_sigle,
  m.libelle_fr  AS ministere_libelle_fr,
  reg.libelle   AS region,
  dep.libelle   AS departement,
  com.libelle   AS commune,
  p.statut_fiche,
  p.score_maturite,
  p.updated_at  AS derniere_mise_a_jour
FROM producteur p
JOIN reseau_archivistique r ON r.id = p.reseau_id
JOIN ministere m            ON m.id = p.ministere_id
JOIN unite_admin com        ON com.id = p.commune_id
LEFT JOIN unite_admin dep   ON dep.id = p.departement_id
LEFT JOIN unite_admin reg   ON reg.id = p.region_id
-- RG-M2-01 : seules les fiches VALIDÉE ou ÉDITÉE sont publiques.
WHERE p.statut_fiche IN ('validee', 'editee')
  AND p.deleted_at IS NULL;

COMMENT ON VIEW v_producteur_public IS
  'Projection publique d''un producteur. EXCLUT par construction : téléphone et '
  'e-mail institutionnels, responsable du local, contact du répondant, et toute '
  'donnée des tables centre_prearchivage et contact_repondant. '
  'RG-M2-02, NFR-C4-01, art. 13 et 22 de la Loi 2024/001.';

-- RG-M2-03 : les fiches sans coordonnées valides ne sont PAS cartographiées,
-- mais restent consultables en liste. Deux vues distinctes, donc.
CREATE VIEW v_producteur_carte AS
SELECT * FROM v_producteur_public WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

COMMENT ON VIEW v_producteur_carte IS
  'RG-M2-03 : sous-ensemble cartographiable. Les producteurs sans coordonnées '
  'valides restent accessibles via v_producteur_public, en liste.';

-- Couche cartographique des centres de préarchivage (TDR §5 : filtre
-- « producteurs uniquement / centres uniquement / les deux »).
CREATE VIEW v_centre_prearchivage_public AS
SELECT
  p.code_producteur,
  p.sigle          AS producteur_sigle,
  c.libelle,
  c.type_batiment,
  c.surface_totale_m2,
  ST_Y(c.geom) AS latitude,
  ST_X(c.geom) AS longitude,
  reg.libelle  AS region
FROM centre_prearchivage c
JOIN producteur p        ON p.id = c.producteur_id
LEFT JOIN unite_admin reg ON reg.id = p.region_id
WHERE c.geom IS NOT NULL
  AND p.statut_fiche IN ('validee', 'editee')
  AND p.deleted_at IS NULL;

COMMENT ON VIEW v_centre_prearchivage_public IS
  'Couche « centres de préarchivage » de la carte. Les champs du responsable '
  '(nom, téléphone, e-mail) sont volontairement absents : données nominatives '
  '(NFR-C4-01).';

-- #############################################################################
-- VUES MATÉRIALISÉES M3 — SDD §12.10
-- Rafraîchies quotidiennement à 03h00 UTC+1 (RG-M3-03), cron applicatif NestJS.
-- #############################################################################

-- Indicateurs nationaux clés (FR-M3-01) — SDD §12.10, transcription littérale.
CREATE MATERIALIZED VIEW mv_kpi_national AS
SELECT
  COUNT(*) AS nb_producteurs_total,
  COUNT(*) FILTER (WHERE statut_fiche = 'validee') AS nb_valides,
  COUNT(*) FILTER (WHERE statut_fiche = 'quarantaine') AS nb_quarantaine,
  COUNT(DISTINCT reseau_id) AS nb_reseaux_couverts,
  COUNT(DISTINCT ministere_id) AS nb_ministeres_couverts,
  NOW() AS horodatage_calcul
FROM producteur
WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX idx_mv_kpi_national_unique ON mv_kpi_national((horodatage_calcul));

-- Répartition par réseau archivistique (FR-M3-02) — SDD §12.10, littérale.
CREATE MATERIALIZED VIEW mv_repartition_par_reseau AS
SELECT
  r.id AS reseau_id,
  r.code,
  r.libelle_fr,
  COUNT(p.id) AS nb_producteurs,
  COUNT(p.id) FILTER (WHERE p.statut_fiche = 'validee') AS nb_valides
FROM reseau_archivistique r
LEFT JOIN producteur p ON p.reseau_id = r.id AND p.deleted_at IS NULL
GROUP BY r.id, r.code, r.libelle_fr;

CREATE UNIQUE INDEX idx_mv_repartition_par_reseau_unique ON mv_repartition_par_reseau(reseau_id);

-- -----------------------------------------------------------------------------
-- Répartition par région (FR-M3-02).
-- RG-M3-02 : « les tableaux de bord publics n'agrègent que des données ; le
-- seuil minimal d'agrégation est de 5 producteurs ». Le drapeau est calculé ici
-- plutôt que laissé à la couche applicative : la protection contre la
-- ré-identification ne doit pas dépendre d'un oubli côté API.
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_repartition_par_region AS
SELECT
  u.id   AS region_id,
  u.code AS region_code,
  u.libelle AS region_libelle,
  COUNT(p.id) AS nb_producteurs,
  COUNT(p.id) FILTER (WHERE p.statut_fiche IN ('validee', 'editee')) AS nb_valides,
  COUNT(p.id) FILTER (WHERE p.geom IS NOT NULL) AS nb_geolocalises,
  ROUND(AVG(p.score_maturite)) AS score_maturite_moyen,
  -- RG-M3-02 : en deçà de 5 producteurs, aucune statistique n'est publiable.
  (COUNT(p.id) >= 5) AS publiable,
  NOW() AS horodatage_calcul
FROM unite_admin u
LEFT JOIN producteur p ON p.region_id = u.id AND p.deleted_at IS NULL
WHERE u.niveau = 'region'
GROUP BY u.id, u.code, u.libelle;

CREATE UNIQUE INDEX idx_mv_repartition_par_region_unique ON mv_repartition_par_region(region_id);

COMMENT ON MATERIALIZED VIEW mv_repartition_par_region IS
  'RG-M3-02 : la colonne `publiable` matérialise le seuil d''agrégation de 5. '
  'Une région comptant moins de 5 producteurs ne doit pas voir ses statistiques '
  'publiées — risque de ré-identification.';

-- Couverture par ministère (FR-M3-02).
CREATE MATERIALIZED VIEW mv_couverture_par_ministere AS
SELECT
  m.id AS ministere_id,
  m.sigle,
  m.libelle_fr,
  COUNT(p.id) AS nb_producteurs,
  COUNT(p.id) FILTER (WHERE p.statut_fiche IN ('validee', 'editee')) AS nb_valides,
  COUNT(p.id) FILTER (WHERE p.statut_fiche = 'quarantaine') AS nb_en_attente,
  ROUND(AVG(p.score_maturite)) AS score_maturite_moyen,
  (COUNT(p.id) >= 5) AS publiable
FROM ministere m
LEFT JOIN producteur p ON p.ministere_id = m.id AND p.deleted_at IS NULL
WHERE m.statut = 'actif'
GROUP BY m.id, m.sigle, m.libelle_fr;

CREATE UNIQUE INDEX idx_mv_couverture_par_ministere_unique ON mv_couverture_par_ministere(ministere_id);

-- -----------------------------------------------------------------------------
-- État de conservation national (FR-M3-08, art. 31-34 : ciblage des inspections).
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_etat_conservation_national AS
SELECT
  COUNT(*) AS nb_evalues,
  COUNT(*) FILTER (WHERE e.indice_risque >= 70) AS nb_risque_eleve,
  COUNT(*) FILTER (WHERE e.indice_risque BETWEEN 40 AND 69) AS nb_risque_modere,
  COUNT(*) FILTER (WHERE e.indice_risque < 40) AS nb_risque_faible,
  COUNT(*) FILTER (WHERE 'moisissures' = ANY(e.etat_materiel)) AS nb_moisissures,
  COUNT(*) FILTER (WHERE 'insectes' = ANY(e.etat_materiel)) AS nb_infestation,
  COUNT(*) FILTER (WHERE 'inondable' = ANY(e.risques_environnementaux)) AS nb_zone_inondable,
  COUNT(*) FILTER (WHERE 'aucun' = ANY(e.dispositifs_securite)) AS nb_sans_securite,
  ROUND(AVG(e.indice_risque)) AS indice_risque_moyen,
  NOW() AS horodatage_calcul
FROM evaluation_conservation e
JOIN producteur p ON p.id = e.producteur_id
WHERE p.deleted_at IS NULL AND p.statut_fiche IN ('validee', 'editee');

CREATE UNIQUE INDEX idx_mv_etat_conservation_unique ON mv_etat_conservation_national((horodatage_calcul));

-- Volumétrie nationale du patrimoine documentaire (FR-M3-01).
CREATE MATERIALIZED VIEW mv_volumetrie_nationale AS
SELECT
  SUM(ps.quantite) FILTER (WHERE ps.support = 'papier') AS total_papier_ml,
  SUM(ps.quantite) FILTER (WHERE ps.support = 'numerique') AS total_supports_numeriques,
  SUM(ps.quantite) FILTER (WHERE ps.support = 'audiovisuel') AS total_audiovisuel,
  SUM(ps.quantite) FILTER (WHERE ps.support = 'plan') AS total_plans,
  SUM(ps.quantite) FILTER (WHERE ps.support = 'carte') AS total_cartes,
  COUNT(DISTINCT pd.producteur_id) AS nb_producteurs_renseignes,
  MIN(pd.annee_doc_plus_ancien) AS annee_document_plus_ancien,
  NOW() AS horodatage_calcul
FROM patrimoine_documentaire pd
JOIN producteur p ON p.id = pd.producteur_id
LEFT JOIN patrimoine_support ps ON ps.patrimoine_id = pd.id
WHERE p.deleted_at IS NULL AND p.statut_fiche IN ('validee', 'editee');

CREATE UNIQUE INDEX idx_mv_volumetrie_nationale_unique ON mv_volumetrie_nationale((horodatage_calcul));

-- -----------------------------------------------------------------------------
-- Rafraîchissement nocturne — RG-M3-03, à 03h00 UTC+1.
-- CONCURRENTLY exige l'index unique présent sur chaque vue : le rafraîchissement
-- ne bloque alors pas les lectures des tableaux de bord.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rafraichir_vues_materialisees()
RETURNS TABLE (vue TEXT, duree_ms INTEGER) AS $$
DECLARE
  v_debut TIMESTAMP;
  v_nom   TEXT;
BEGIN
  FOREACH v_nom IN ARRAY ARRAY[
    'mv_kpi_national', 'mv_repartition_par_reseau', 'mv_repartition_par_region',
    'mv_couverture_par_ministere', 'mv_etat_conservation_national', 'mv_volumetrie_nationale'
  ] LOOP
    v_debut := clock_timestamp();
    EXECUTE format('REFRESH MATERIALIZED VIEW CONCURRENTLY cnipac.%I', v_nom);
    vue := v_nom;
    duree_ms := EXTRACT(MILLISECONDS FROM clock_timestamp() - v_debut)::INTEGER;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION rafraichir_vues_materialisees IS
  'RG-M3-03 : rafraîchissement quotidien à 03h00 UTC+1, déclenché par le cron '
  'applicatif NestJS (ADR-005 du SDD). Les utilisateurs voient toujours '
  'l''horodatage de dernière mise à jour porté par chaque vue.';

-- -----------------------------------------------------------------------------
-- Vue d'exploitation : file d'attente de validation (UC-M4-01).
-- -----------------------------------------------------------------------------
CREATE VIEW v_file_validation AS
SELECT
  s.id                AS soumission_id,
  s.kobo_instance_id,
  s.date_soumission_kobo,
  s.date_remplissage,
  s.enqueteur,
  s.statut_traitement,
  s.cle_deduplication,
  s.doublon_de_id,
  l.source            AS source_ingestion,
  s.payload ->> 'nom_institution' AS nom_declare,
  EXTRACT(DAY FROM NOW() - s.date_soumission_kobo)::INTEGER AS anciennete_jours
FROM soumission_kobo s
JOIN lot_ingestion l ON l.id = s.lot_ingestion_id
WHERE s.statut_traitement IN ('recue', 'en_validation', 'doublon_potentiel')
ORDER BY s.date_soumission_kobo ASC;

COMMENT ON VIEW v_file_validation IS
  'File d''attente de la console de quarantaine (UC-M4-01, écran IHM-ADM-01). '
  'Ordonnée par ancienneté : l''ancienneté médiane de cette file est '
  'l''indicateur qui révèle le plus tôt un engorgement de la validation ANC.';
