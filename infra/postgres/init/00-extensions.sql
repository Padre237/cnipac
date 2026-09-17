-- Extensions requises — SDD §12.
-- Executees une seule fois, a l'initialisation du cluster.

-- PostGIS : requetes spatiales, clustering serveur, enveloppe territoriale (RG-M2-03).
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Recherche par similarite : UC-M2-04 (recherche par nom ou sigle),
-- detection de doublons RG-M1-03 (triplet sigle/ministere/commune).
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Identifiants opaques pour l'API publique (ADR-037 : ne jamais exposer
-- d'identifiant sequentiel interne).
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Supervision des requetes lentes (ADR-038, NFR-C1-02).
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Compte de metriques en lecture seule, pour postgres-exporter.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cnipac_metrics') THEN
    CREATE ROLE cnipac_metrics WITH LOGIN;
  END IF;
END
$$;
GRANT pg_monitor TO cnipac_metrics;

-- Configuration de recherche francaise sans accents : « Societe » doit
-- retrouver « SOCIÉTÉ » (NFR-C8-02).
CREATE TEXT SEARCH CONFIGURATION fr_unaccent (COPY = french);
ALTER TEXT SEARCH CONFIGURATION fr_unaccent
  ALTER MAPPING FOR hword, hword_part, word WITH unaccent, french_stem;
