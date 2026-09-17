#!/usr/bin/env bash
# =============================================================================
# Validation du schéma PostgreSQL CNIPAC.
#
# Applique l'intégralité du schéma et des jeux de référentiels sur une base
# JETABLE, puis exerce les règles de gestion critiques par des assertions.
#
# Deux modes :
#   - PostGIS présent  : validation intégrale ;
#   - PostGIS absent   : mode dégradé, les types géométriques sont remplacés par
#     les types natifs PostgreSQL et ST_X/ST_Y par des substituts. Tout le reste
#     — contraintes, triggers, fonctions, vues, référentiels — est réellement
#     exercé. Le mode est annoncé dans le compte rendu.
#
# Usage : ./scripts/valider-schema-sql.sh [nom_base]
# =============================================================================
set -Eeuo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${1:-cnipac_validation_$$}"
SCHEMA="${RACINE}/infra/postgres/schema"
SEED="${RACINE}/infra/postgres/seed"
TRAVAIL="$(mktemp -d)"

vert()  { printf '\033[32m%s\033[0m\n' "$*"; }
rouge() { printf '\033[31m%s\033[0m\n' "$*"; }
gris()  { printf '\033[90m%s\033[0m\n' "$*"; }

nettoyer() { dropdb --if-exists "$BASE" 2>/dev/null || true; rm -rf "$TRAVAIL"; }
trap nettoyer EXIT

POSTGIS_DISPO=$(psql -d postgres -tAc \
  "SELECT COUNT(*) FROM pg_available_extensions WHERE name = 'postgis'")

createdb "$BASE"

if [[ "$POSTGIS_DISPO" == "0" ]]; then
  gris "PostGIS indisponible — validation en mode dégradé (types géométriques substitués)."
  cat > "${TRAVAIL}/00_shim.sql" <<'SHIM'
-- Substituts de PostGIS, UNIQUEMENT pour la validation hors ligne.
CREATE SCHEMA IF NOT EXISTS cnipac;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE OR REPLACE FUNCTION public.st_x(p point) RETURNS double precision AS $$ SELECT p[0] $$ LANGUAGE sql IMMUTABLE;
CREATE OR REPLACE FUNCTION public.st_y(p point) RETURNS double precision AS $$ SELECT p[1] $$ LANGUAGE sql IMMUTABLE;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'fr_unaccent') THEN
    CREATE TEXT SEARCH CONFIGURATION fr_unaccent (COPY = french);
  END IF;
END $$;
SHIM
  PRELUDE="${TRAVAIL}/00_shim.sql"
  SUBSTITUER=1
else
  gris "PostGIS disponible — validation intégrale."
  PRELUDE=""
  SUBSTITUER=0
fi

preparer() {
  local src="$1" dst="${TRAVAIL}/$(basename "$1")"
  if [[ $SUBSTITUER -eq 1 ]]; then
    sed -e 's/geometry(Point, 4326)/point/g' \
        -e 's/geometry(MultiPolygon, 4326)/polygon/g' \
        -e '/CREATE EXTENSION IF NOT EXISTS postgis/d' \
        -e '/CREATE EXTENSION IF NOT EXISTS pg_stat_statements/d' \
        "$src" > "$dst"
  else
    cp "$src" "$dst"
  fi
  echo "$dst"
}

echec=0
appliquer() {
  local fichier; fichier="$(preparer "$1")"
  if psql -d "$BASE" -v ON_ERROR_STOP=1 -q -f "$fichier" >"${TRAVAIL}/sortie.log" 2>&1; then
    printf '  %-34s %s\n' "$(basename "$1")" "$(vert OK)"
  else
    printf '  %-34s %s\n' "$(basename "$1")" "$(rouge ECHEC)"
    sed -n '1,12p' "${TRAVAIL}/sortie.log" | sed 's/^/      /'
    echec=1
  fi
}

[[ -n "$PRELUDE" ]] && psql -d "$BASE" -q -v ON_ERROR_STOP=1 -f "$PRELUDE"

echo ""
echo "SCHÉMA"
for f in "$SCHEMA"/*.sql; do appliquer "$f"; done
[[ $echec -eq 0 ]] || { rouge "Le schéma ne s'applique pas. Arrêt."; exit 1; }

echo ""
echo "RÉFÉRENTIELS"
for f in "$SEED"/2*.sql; do appliquer "$f"; done
[[ $echec -eq 0 ]] || { rouge "Les référentiels ne s'appliquent pas. Arrêt."; exit 1; }

echo ""
echo "ASSERTIONS"
psql -d "$BASE" -v ON_ERROR_STOP=1 -q -f "${RACINE}/infra/postgres/tests/assertions.sql"
