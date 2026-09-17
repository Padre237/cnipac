-- =============================================================================
-- CNIPAC — 00 : schéma, extensions et paramètres de session
-- Sources : SDD V4.0 §11.8 (schéma unique `cnipac`), §12.1 (conventions),
--           §12.13.2 (indexation), SRS V2.0 §12.
-- =============================================================================

-- SDD §11.8 : « toutes les tables résident dans une seule base PostgreSQL,
-- dans un schéma unique (au sens PostgreSQL du terme — schéma `cnipac`) ».
CREATE SCHEMA IF NOT EXISTS cnipac;

-- Extensions. Installées dans `public` : PostGIS et pgcrypto y sont attendues
-- par convention, et les fonctions restent accessibles via le search_path.
CREATE EXTENSION IF NOT EXISTS postgis;              -- geometry(Point,4326), index GiST
CREATE EXTENSION IF NOT EXISTS pgcrypto;             -- digest() : hash-chaining audit (SDD §12.7)
CREATE EXTENSION IF NOT EXISTS pg_trgm;              -- recherche par similarité (UC-M2-04, RG-M1-03)
CREATE EXTENSION IF NOT EXISTS unaccent;             -- « SOCIÉTÉ » = « societe » (NFR-C8-02)
CREATE EXTENSION IF NOT EXISTS btree_gin;            -- index GIN composés (§12.13.2)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;   -- supervision des requêtes lentes

-- NFR-C8-02 : recherche française insensible aux accents.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'fr_unaccent') THEN
    CREATE TEXT SEARCH CONFIGURATION fr_unaccent (COPY = french);
    ALTER TEXT SEARCH CONFIGURATION fr_unaccent
      ALTER MAPPING FOR hword, hword_part, word WITH unaccent, french_stem;
  END IF;
END
$$;

-- NFR-C8-03 : stockage UTC, affichage applicatif Africa/Douala (UTC+1).
SET search_path TO cnipac, public;

COMMENT ON SCHEMA cnipac IS
  'Schéma unique du système CNIPAC — Carte Numérique Interactive des Producteurs '
  'd''Archives au Cameroun. Référence : SDD V4.0 §11.8 et chapitre 12.';
