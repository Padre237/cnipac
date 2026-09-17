#!/bin/bash
# Installation du schéma CNIPAC à l'initialisation du cluster.
# Exécuté par docker-entrypoint-initdb.d, une seule fois, à la création du volume.
set -Eeuo pipefail

echo "[CNIPAC] Installation du schéma"
for f in /schema/*.sql; do
  echo "  $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -q -f "$f"
done

echo "[CNIPAC] Chargement des référentiels"
for f in /seed/2*.sql; do
  echo "  $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -q -f "$f"
done

echo "[CNIPAC] Schéma installé : $(psql -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='cnipac' AND table_type='BASE TABLE'" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB") tables."
