#!/usr/bin/env bash
# =============================================================================
# Sauvegarde quotidienne — SDD §4.4 et §27.4, NFR-C2-05.
# « pg_dump + chiffrement age + rsync — outils standards Linux, scripts simples,
#   restauration testee trimestriellement. »
#
# Retention : 30 jours en local, 12 mois en externalise (NFR-C2-05).
# A planifier par cron sur l'hote : 0 2 * * *
# =============================================================================
set -Eeuo pipefail

BASE_LOCALE="/srv/cnipac/sauvegardes"
SITE_DR="${CNIPAC_SITE_DR:-cnipac-backup@dr.cenadi.cm:/sauvegardes/cnipac}"
CLE_PUBLIQUE="/srv/cnipac/secrets/cle_publique_sauvegardes"
HORODATAGE="$(date +%Y%m%dT%H%M%S)"
ARCHIVE="${BASE_LOCALE}/cnipac-${HORODATAGE}.dump.age"

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

mkdir -p "$BASE_LOCALE"

log "1/4 — dump logique PostgreSQL"
docker compose -f /srv/cnipac/infra/compose/docker-compose.yml \
               -f /srv/cnipac/infra/compose/docker-compose.prod.yml \
  exec -T postgres pg_dump -U cnipac -Fc cnipac > "/tmp/cnipac-${HORODATAGE}.dump"

log "2/4 — chiffrement age (NFR-C3-02 : donnees chiffrees au repos)"
age -r "$(cat "$CLE_PUBLIQUE")" -o "$ARCHIVE" "/tmp/cnipac-${HORODATAGE}.dump"
shred -u "/tmp/cnipac-${HORODATAGE}.dump"
chmod 0400 "$ARCHIVE"

log "3/4 — externalisation vers le site de reprise"
rsync -az --partial "$ARCHIVE" "$SITE_DR/" \
  || log "ATTENTION : externalisation echouee, la copie locale existe."

log "4/4 — purge selon la retention (30 jours en local — NFR-C2-05)"
find "$BASE_LOCALE" -name 'cnipac-*.dump.age' -mtime +30 -delete

log "Sauvegarde ${HORODATAGE} terminee — $(du -h "$ARCHIVE" | cut -f1)"

# Metrique exposee a Prometheus pour l'alerte de fraicheur (NFR-C2-05).
echo "cnipac_derniere_sauvegarde_horodatage $(date +%s)" \
  > /var/lib/node_exporter/textfile_collector/cnipac_sauvegarde.prom 2>/dev/null || true
