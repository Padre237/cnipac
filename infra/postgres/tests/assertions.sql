-- =============================================================================
-- CNIPAC — assertions de validation du schéma
-- Exerce les règles de gestion qui sont appliquées PAR LA BASE, et vérifie
-- qu'elles rejettent effectivement ce qu'elles doivent rejeter.
-- Une contrainte qu'on n'a jamais vue refuser n'est pas une contrainte vérifiée.
-- =============================================================================
SET search_path TO cnipac, public;
\set ON_ERROR_STOP on

CREATE OR REPLACE FUNCTION pg_temp.attendre_echec(p_sql TEXT, p_libelle TEXT)
RETURNS VOID AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  OK    % (rejeté : %)', p_libelle, left(SQLERRM, 70);
    RETURN;
  END;
  RAISE EXCEPTION 'ASSERTION EN ÉCHEC : "%" aurait dû être rejeté et ne l''a pas été', p_libelle;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.verifier(p_condition BOOLEAN, p_libelle TEXT)
RETURNS VOID AS $$
BEGIN
  IF NOT p_condition THEN
    RAISE EXCEPTION 'ASSERTION EN ÉCHEC : %', p_libelle;
  END IF;
  RAISE NOTICE '  OK    %', p_libelle;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_n INTEGER; v_reseau UUID; v_min UUID; v_com UUID; v_prod UUID;
  v_user UUID; v_lot UUID; v_pat UUID; v_centre UUID; v_code VARCHAR;
  v_h1 CHAR(64); v_h2 CHAR(64); v_intacte BOOLEAN;
BEGIN
RAISE NOTICE '--- Référentiels ---';
SELECT COUNT(*) INTO v_n FROM reseau_archivistique;
PERFORM pg_temp.verifier(v_n = 9, format('9 réseaux archivistiques SND30 (trouvé : %s)', v_n));

SELECT COUNT(*) INTO v_n FROM unite_admin WHERE niveau = 'region';
PERFORM pg_temp.verifier(v_n = 10, format('10 régions (trouvé : %s)', v_n));

SELECT COUNT(*) INTO v_n FROM unite_admin WHERE niveau = 'departement';
PERFORM pg_temp.verifier(v_n = 58, format('58 départements (trouvé : %s)', v_n));

SELECT COUNT(*) INTO v_n FROM unite_admin WHERE niveau = 'arrondissement';
PERFORM pg_temp.verifier(v_n = 290, format('290 arrondissements du XLSForm (trouvé : %s)', v_n));

SELECT COUNT(*) INTO v_n FROM unite_admin WHERE niveau <> 'national' AND parent_id IS NULL;
PERFORM pg_temp.verifier(v_n = 0, 'aucune unité administrative orpheline');

SELECT COUNT(*) INTO v_n FROM role;
PERFORM pg_temp.verifier(v_n = 8, format('8 rôles RBAC — AC-P1-06 (trouvé : %s)', v_n));

SELECT COUNT(*) INTO v_n FROM nomenclature WHERE source = 'xlsform';
PERFORM pg_temp.verifier(v_n >= 80, format('libellés des listes du XLSForm (trouvé : %s)', v_n));

RAISE NOTICE '--- Jeu de données de travail ---';
SELECT id INTO v_reseau FROM reseau_archivistique WHERE code = 'NUM';
SELECT id INTO v_min    FROM ministere WHERE sigle = 'MINPOSTEL';
SELECT id INTO v_com    FROM unite_admin WHERE niveau = 'arrondissement' LIMIT 1;

INSERT INTO utilisateur (email, hash_password, nom, prenom)
VALUES ('archiviste@test.cnipac.cm', '$argon2id$factice', 'NGONO', 'Marie')
RETURNING id INTO v_user;

v_code := generer_code_producteur(v_reseau, v_min, 'ANTIC');
PERFORM pg_temp.verifier(v_code ~ '^CMR-[A-Z0-9]+-[A-Z0-9]+-[A-Z0-9]+-[0-9]+$',
  format('RG-M1-02 : code généré au bon format (%s)', v_code));

INSERT INTO producteur (code_producteur, nom_officiel, sigle, type_entite, statut_admin,
                        reseau_id, ministere_id, commune_id, geom, statut_fiche)
VALUES (v_code, 'Agence Nationale des TIC', 'ANTIC', 'etablissement_public', 'parapublic',
        v_reseau, v_min, v_com, point(11.5180, 3.8592), 'nouvelle')
RETURNING id INTO v_prod;

RAISE NOTICE '--- Règles de gestion appliquées par la base ---';

SELECT region_id IS NOT NULL AND departement_id IS NOT NULL INTO v_intacte
FROM producteur WHERE id = v_prod;
PERFORM pg_temp.verifier(v_intacte, 'hiérarchie administrative déduite automatiquement de la commune');

PERFORM pg_temp.attendre_echec(
  format('UPDATE producteur SET code_producteur = ''CMR-XXX-YYY-ZZZ-9999'' WHERE id = %L', v_prod),
  'RG-M1-02 : le code producteur est immuable');

PERFORM pg_temp.attendre_echec(
  format('UPDATE producteur SET statut_fiche = ''validee'' WHERE id = %L', v_prod),
  'RG-M1-05 : nouvelle -> validee interdit (passage obligatoire par la quarantaine)');

UPDATE producteur SET statut_fiche = 'quarantaine' WHERE id = v_prod;
UPDATE producteur SET statut_fiche = 'validee', date_validation = NOW(), valide_par = v_user WHERE id = v_prod;
RAISE NOTICE '  OK    RG-M1-05 : nouvelle -> quarantaine -> validee autorisé';

PERFORM pg_temp.attendre_echec(
  format('UPDATE producteur SET statut_fiche = ''quarantaine'' WHERE id = %L', v_prod),
  'RG-M1-05 : aucune transition arrière depuis validee');

PERFORM pg_temp.attendre_echec(
  format('UPDATE producteur SET geom = point(2.3522, 48.8566) WHERE id = %L', v_prod),
  'RG-M2-03 / DQ-01 : coordonnées hors enveloppe Cameroun (Paris) refusées');

PERFORM pg_temp.attendre_echec(
  format('UPDATE producteur SET telephone = ''0612345678'' WHERE id = %L', v_prod),
  'format de téléphone hors +237 refusé');

PERFORM pg_temp.attendre_echec(
  format('UPDATE producteur SET email = ''pas-un-email'' WHERE id = %L', v_prod),
  'format d''adresse électronique invalide refusé');

RAISE NOTICE '--- Immuabilité (art. 32 Loi 2024/001, RG-M1-04) ---';

INSERT INTO lot_ingestion (source, kobo_form_id, statut, fin_le, nb_recues)
VALUES ('kobo', 'aw2T2qSbuxp3GQdm3wdySZ', 'termine', NOW(), 1) RETURNING id INTO v_lot;

INSERT INTO soumission_kobo (kobo_instance_id, kobo_form_id, payload, date_soumission_kobo, lot_ingestion_id)
VALUES ('uuid:test-0001', 'aw2T2qSbuxp3GQdm3wdySZ', '{"nom_institution":"ANTIC"}'::jsonb, NOW(), v_lot);

PERFORM pg_temp.attendre_echec(
  'UPDATE soumission_kobo SET enqueteur = ''autre'' WHERE kobo_instance_id = ''uuid:test-0001''',
  'RG-M1-04 : soumission Kobo immuable (UPDATE rejeté)');

PERFORM pg_temp.attendre_echec(
  'DELETE FROM soumission_kobo WHERE kobo_instance_id = ''uuid:test-0001''',
  'RG-M1-04 : soumission Kobo immuable (DELETE rejeté)');

INSERT INTO evenement_audit (utilisateur_id, role_utilise, action, ressource_type, ressource_id)
VALUES (v_user, 'R-03', 'VALIDER_FICHE', 'producteur', v_prod);
INSERT INTO evenement_audit (utilisateur_id, role_utilise, action, ressource_type, ressource_id)
VALUES (v_user, 'R-03', 'EDITER_FICHE', 'producteur', v_prod);

SELECT hash INTO v_h1 FROM evenement_audit ORDER BY sequence ASC LIMIT 1;
SELECT prev_hash INTO v_h2 FROM evenement_audit ORDER BY sequence DESC LIMIT 1;
PERFORM pg_temp.verifier(v_h1 IS NOT NULL AND v_h1 = v_h2,
  'ADR-009 : le second événement chaîne bien sur le hachage du premier');

PERFORM pg_temp.attendre_echec(
  'UPDATE evenement_audit SET action = ''FALSIFIE'' WHERE action = ''VALIDER_FICHE''',
  'art. 32 Loi 2024/001 : journal d''audit INSERT-ONLY (UPDATE rejeté)');

PERFORM pg_temp.attendre_echec(
  'DELETE FROM evenement_audit',
  'art. 32 Loi 2024/001 : journal d''audit INSERT-ONLY (DELETE rejeté)');

PERFORM pg_temp.attendre_echec(
  'TRUNCATE evenement_audit',
  'art. 32 Loi 2024/001 : journal d''audit INSERT-ONLY (TRUNCATE rejeté)');

SELECT intacte INTO v_intacte FROM verifier_chaine_audit('validation');
PERFORM pg_temp.verifier(v_intacte, 'la chaîne de hachage du journal d''audit est intacte');

RAISE NOTICE '--- Sections du formulaire Kobo ---';

INSERT INTO centre_prearchivage (producteur_id, type_batiment, surface_totale_m2, surface_occupee_m2,
                                 responsable_nom, geom)
VALUES (v_prod, 'entrepot_archives', 200.00, 150.00, 'MBALLA Jean', point(11.5190, 3.8600))
RETURNING id INTO v_centre;

PERFORM pg_temp.attendre_echec(
  format('UPDATE centre_prearchivage SET surface_occupee_m2 = 500 WHERE id = %L', v_centre),
  'surface occupée supérieure à la surface totale refusée');

INSERT INTO centre_personnel (centre_id, type_personnel, effectif) VALUES (v_centre, 'arch_ass', 2);

INSERT INTO patrimoine_documentaire (producteur_id, annee_doc_plus_ancien, annee_doc_plus_recent,
                                     materiau_rayonnage, types_boites)
VALUES (v_prod, 1960, 2026, 'metal', ARRAY['ignifuge']::type_boite_enum[])
RETURNING id INTO v_pat;

PERFORM pg_temp.attendre_echec(
  format('UPDATE patrimoine_documentaire SET annee_doc_plus_ancien = 2030 WHERE id = %L', v_pat),
  'DQ-04 : année du document le plus ancien postérieure au plus récent refusée');

INSERT INTO patrimoine_support (patrimoine_id, support, quantite, unite)
VALUES (v_pat, 'papier', 1250.50, 'metre_lineaire');

PERFORM pg_temp.attendre_echec(
  format('INSERT INTO patrimoine_support (patrimoine_id, support, quantite, unite)
          VALUES (%L, ''numerique'', 10, ''metre_lineaire'')', v_pat),
  'Kobo IV.1 : seul le papier se mesure en mètres linéaires');

INSERT INTO evaluation_conservation (producteur_id, etat_materiel, risques_environnementaux, dispositifs_securite)
VALUES (v_prod, ARRAY['moisissures','insectes']::etat_materiel_enum[],
        ARRAY['humidite']::risque_environnemental_enum[],
        ARRAY['extincteurs']::dispositif_securite_enum[]);

SELECT indice_risque INTO v_n FROM evaluation_conservation WHERE producteur_id = v_prod;
PERFORM pg_temp.verifier(v_n = 32, format('FR-M3-08 : indice de risque calculé automatiquement (%s = 20 dégradations + 12 risque)', v_n));

PERFORM pg_temp.attendre_echec(
  format('INSERT INTO evaluation_conservation (producteur_id, dispositifs_securite)
          VALUES (%L, ARRAY[''aucun'',''biometrie'']::dispositif_securite_enum[])',
         gen_random_uuid()),
  '« aucun dispositif » est exclusif de tout autre dispositif');

INSERT INTO maturite_archivistique (producteur_id, outils_gestion, instruments_recherche,
                                    service_archives_dedie, niveau_validation)
VALUES (v_prod, ARRAY['plan_classement','calendrier_conservation']::outil_gestion_enum[],
        ARRAY['bordereaux_versement']::instrument_recherche_enum[], TRUE, 'archives_nationales');

SELECT score_maturite INTO v_n FROM producteur WHERE id = v_prod;
-- 25 service + 15 personnel (archivistes assermentés) + 20 locaux (entrepôt dédié)
-- + 20 plan de classement + 10 calendrier + 10 instruments = 100
PERFORM pg_temp.verifier(v_n = 100,
  format('RG-M3-01 : indice de maturité recalculé par trigger (%s/100)', v_n));

RAISE NOTICE '--- Confidentialité (NFR-C4-01, RG-M2-02) ---';

SELECT COUNT(*) INTO v_n FROM information_schema.columns
WHERE table_schema = 'cnipac' AND table_name = 'v_producteur_public'
  AND column_name IN ('telephone','email','responsable_nom','responsable_tel','responsable_email','coordonnees');
PERFORM pg_temp.verifier(v_n = 0, 'la vue publique n''expose aucune donnée nominative');

SELECT COUNT(*) INTO v_n FROM v_producteur_public WHERE code_producteur = v_code;
PERFORM pg_temp.verifier(v_n = 1, 'RG-M2-01 : la fiche validée apparaît dans la vue publique');

UPDATE producteur SET statut_fiche = 'archivee' WHERE id = v_prod;
SELECT COUNT(*) INTO v_n FROM v_producteur_public WHERE code_producteur = v_code;
PERFORM pg_temp.verifier(v_n = 0, 'RG-M2-01 : une fiche archivée disparaît de la vue publique');

RAISE NOTICE '--- Vues matérialisées (M3) ---';
PERFORM rafraichir_vues_materialisees();
SELECT nb_producteurs_total INTO v_n FROM mv_kpi_national;
PERFORM pg_temp.verifier(v_n = 1, 'les vues matérialisées se rafraîchissent en CONCURRENTLY');

SELECT COUNT(*) INTO v_n FROM mv_repartition_par_region WHERE publiable;
PERFORM pg_temp.verifier(v_n = 0, 'RG-M3-02 : aucune région publiable en deçà de 5 producteurs');

RAISE NOTICE '';
RAISE NOTICE 'TOUTES LES ASSERTIONS SONT PASSÉES.';
END $$;
