-- =============================================================================
-- CNIPAC — 20 : réseaux archivistiques
-- Source : TDR §7 et SND30 (Stratégie Nationale de Développement 2020-2030),
--          SRS §12.10 (référentiel RÉSEAUX_ARCHIVISTIQUES, 9 entrées).
-- Le nombre est fermé : neuf réseaux, ni plus ni moins.
-- =============================================================================
SET search_path TO cnipac, public;

INSERT INTO reseau_archivistique (code, libelle_fr, libelle_en, description_fr, ordre_affichage) VALUES
  ('ENE', 'Énergie', 'Energy',
   'Hydroélectricité, énergies alternatives et exportation d''électricité.', 1),
  ('AGR', 'Agro-industrie', 'Agro-industry',
   'Transformation des produits agricoles pour l''autosuffisance alimentaire et l''exportation sous-régionale.', 2),
  ('NUM', 'Numérique', 'Digital',
   'Infrastructures, contenus, services et assemblage d''équipements numériques.', 3),
  ('FOR', 'Forêt-Bois', 'Forestry and Timber',
   'Plantations, transformation jusqu''à la troisième transformation, meubles.', 4),
  ('TEX', 'Textile-Confection-Cuir', 'Textile, Clothing and Leather',
   'Augmentation de la production cotonnière et intégration de la chaîne de valeur.', 5),
  ('MIN', 'Mines-Métallurgie-Sidérurgie', 'Mining, Metallurgy and Steel',
   'Extraction minière, métallurgie et sidérurgie.', 6),
  ('HYD', 'Hydrocarbures-Pétrochimie-Raffinage', 'Hydrocarbons, Petrochemicals and Refining',
   'Exploration, production, raffinage et pétrochimie.', 7),
  ('CHI', 'Chimie-Pharmacie', 'Chemicals and Pharmaceuticals',
   'Industrie chimique et production pharmaceutique.', 8),
  ('CST', 'Construction-Services professionnels, scientifiques et techniques',
   'Construction and Professional, Scientific and Technical Services',
   'Bâtiment, travaux publics et services professionnels, scientifiques et techniques. '
   'Réseau de rattachement par défaut des administrations à vocation générale.', 9)
ON CONFLICT (code) DO UPDATE
  SET libelle_fr = EXCLUDED.libelle_fr,
      libelle_en = EXCLUDED.libelle_en,
      updated_at = NOW();

DO $$
DECLARE v_nb INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_nb FROM reseau_archivistique;
  IF v_nb <> 9 THEN
    RAISE EXCEPTION 'Le référentiel doit compter exactement 9 réseaux (SND30), or il en compte %', v_nb;
  END IF;
END $$;
