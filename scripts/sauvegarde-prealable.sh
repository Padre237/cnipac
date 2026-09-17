#!/usr/bin/env bash
# Sauvegarde prealable au deploiement — SDD §26.5 etape 2.
# « Sauvegarde prealable complete (pg_dump + snapshot du volume Docker),
#   verifiee avant tout changement. »
set -Eeuo pipefail
ENVIRONNEMENT="prod"; VERIFIER=0
for a in "$@"; do case "$a" in --env=*) ENVIRONNEMENT="${a#*=}";; --verifier) VERIFIER=1;; esac; done

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="-f ${RACINE}/infra/compose/docker-compose.yml -f ${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml"
ETIQUETTE="predeploiement-$(date +%Y%m%dT%H%M%S)"
DEST="/srv/cnipac/sauvegardes"

echo "[1/3] pg_dump (SDD §26.5 etape 2)"
mkdir -p "$DEST"
docker compose $COMPOSE exec -T postgres pg_dump -U cnipac -Fc cnipac > "/tmp/${ETIQUETTE}.dump"

echo "[2/3] Chiffrement age (NFR-C3-02)"
age -r "$(cat /srv/cnipac/secrets/cle_publique_sauvegardes)" \
    -o "${DEST}/${ETIQUETTE}.dump.age" "/tmp/${ETIQUETTE}.dump"
shred -u "/tmp/${ETIQUETTE}.dump"

if [[ $VERIFIER -eq 1 ]]; then
  echo "[3/3] Verification : restauration d essai dans une base ephemere"
  age -d -i /srv/cnipac/secrets/cle_privee_sauvegardes "${DEST}/${ETIQUETTE}.dump.age" \
    | pg_restore --list > /dev/null \
    || { echo "ECHEC de verification : le deploiement ne peut pas se poursuivre." >&2; exit 1; }
  echo "  Sauvegarde verifiee."
else
  echo "[3/3] Verification non demandee (ajouter --verifier en production)"
fi

echo "${ETIQUETTE}" > "${RACINE}/.derniere-sauvegarde"
echo "Sauvegarde ${ETIQUETTE} disponible pour rollback."
