#!/usr/bin/env bash
# =============================================================================
# Deploiement CNIPAC — ADR-032 (Blue-Green automatise), ADR-020 (tier donnees),
# ADR-024 (verification de signature), ADR-034 (isolation des donnees).
#
# La DECISION de deployer reste humaine (approbation GitHub Environment).
# Ce script n'execute que la sequence, toujours a l'identique.
#
# Usage :
#   ./deploy.sh --env=preprod --version=v0.1.0 --strategie=blue-green
#   ./deploy.sh --env=prod --etape=demarrer-green|basculer|planifier-arret-blue
#   ./deploy.sh --env=prod --mode=manuel      # procedure SDD §26.5 pas a pas
# =============================================================================
set -Eeuo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# SDD §26.3 : base commune + override par environnement.
COMPOSE_BASE="${RACINE}/infra/compose/docker-compose.yml"

ENVIRONNEMENT=""; VERSION=""; STRATEGIE="blue-green"; ETAPE="complet"; MODE="auto"

for arg in "$@"; do
  case "$arg" in
    --env=*)        ENVIRONNEMENT="${arg#*=}" ;;
    --version=*)    VERSION="${arg#*=}" ;;
    --strategie=*)  STRATEGIE="${arg#*=}" ;;
    --etape=*)      ETAPE="${arg#*=}" ;;
    --mode=*)       MODE="${arg#*=}" ;;
    --delai=*)      DELAI="${arg#*=}" ;;
    *) echo "Argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

log()    { printf '\033[90m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
erreur() { printf '\033[31m[ERREUR]\033[0m %s\n' "$*" >&2; exit 1; }
ok()     { printf '\033[32m[OK]\033[0m %s\n' "$*"; }

# -----------------------------------------------------------------------------
# GARDE-FOU — les volumes portent les donnees de production (SDD §26.3).
# `docker compose down -v` les detruirait : l'option est refusee ici.
# -----------------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    *-v|*--volumes)
      erreur "L'option -v/--volumes est interdite : elle detruirait les volumes postgres_data et redis_data." ;;
  esac
done

[[ -n "$ENVIRONNEMENT" ]] || erreur "--env est obligatoire (dev|preprod|prod)."
case "$ENVIRONNEMENT" in dev|preprod|prod) ;; *) erreur "Environnement inconnu : $ENVIRONNEMENT" ;; esac

REGISTRY="${CNIPAC_REGISTRY:-ghcr.io}"
PREFIXE="${CNIPAC_IMAGE_PREFIX:-cenadi-cm/cnipac}"

# -----------------------------------------------------------------------------
# GARDE-FOU 2 — ADR-024 : une image non signee n'est jamais deployee.
# C'est la barriere qui empeche le deploiement d'une image construite hors CI.
# -----------------------------------------------------------------------------
verifier_signature() {
  local composant="$1"
  local image="${REGISTRY}/${PREFIXE}-${composant}:${VERSION}"
  log "Verification de la signature cosign de ${image}"
  if ! cosign verify --key "${RACINE}/infra/cosign.pub" "$image" >/dev/null 2>&1; then
    erreur "Signature absente ou invalide pour ${image}.
  Une image non signee par la cle CNIPAC ne peut pas etre deployee (ADR-024).
  Verifier qu'elle a bien ete produite par le workflow release.yml."
  fi
  ok "Signature verifiee : ${composant}"
}

# -----------------------------------------------------------------------------
# GARDE-FOU 3 — ADR-034 : jamais de donnees reelles hors production.
# -----------------------------------------------------------------------------
verifier_isolation_donnees() {
  [[ "$ENVIRONNEMENT" == "prod" ]] && return 0
  if [[ "${CNIPAC_SOURCE_DONNEES:-synthetique}" != "synthetique" ]]; then
    erreur "Tentative de deploiement en ${ENVIRONNEMENT} avec des donnees non synthetiques.
  ADR-034 et SDD §8.1 : aucune donnee reelle ne transite par DEV ou PREPROD.
  Une donnee nominative de point focal est protegee par NFR-C4-01 et la Loi 2024/001."
  fi
}

couleur_active() {
  docker inspect -f '{{index .Config.Labels "cnipac.couleur"}}' "cnipac-backend-${ENVIRONNEMENT}" 2>/dev/null || echo "blue"
}

demarrer_green() {
  local active inactive
  active="$(couleur_active)"
  inactive=$([[ "$active" == "blue" ]] && echo green || echo blue)
  log "Couleur active : ${active} — demarrage de ${inactive} (sans trafic)"
  CNIPAC_COULEUR="$inactive" CNIPAC_VERSION="$VERSION" \
    docker compose -f "$COMPOSE_BASE" -f "${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml" --profile "$inactive" up -d --wait --no-deps backend frontend
  echo "$inactive" > "${RACINE}/.deploiement-couleur-cible"
  ok "Instance ${inactive} demarree en version ${VERSION}, hors trafic"
}

basculer() {
  local cible; cible="$(cat "${RACINE}/.deploiement-couleur-cible")"
  log "Bascule du reverse proxy vers ${cible}"
  # Le basculement consiste a permuter un lien symbolique lu par Nginx, puis a
  # recharger sa configuration : quelques secondes, sans coupure de connexion.
  ln -sfn "${RACINE}/infra/nginx/blue-green/upstream-${cible}.conf" \
          "${RACINE}/infra/nginx/blue-green/upstream-actif.conf"
  docker compose -f "$COMPOSE_BASE" -f "${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml" exec -T nginx nginx -t
  docker compose -f "$COMPOSE_BASE" -f "${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml" exec -T nginx nginx -s reload
  ok "Trafic bascule vers ${cible}"
}

planifier_arret_blue() {
  local cible ancienne
  cible="$(cat "${RACINE}/.deploiement-couleur-cible")"
  ancienne=$([[ "$cible" == "blue" ]] && echo green || echo blue)
  log "Arret de ${ancienne} planifie dans ${DELAI:-24h} — rollback instantane possible jusque-la"
  echo "docker compose -f ${COMPOSE_APP} --profile ${ancienne} stop" | at now + "${DELAI:-24 hours}" 2>/dev/null \
    || log "Commande 'at' indisponible : arreter ${ancienne} manuellement (runbook RB-02)."
}

# -----------------------------------------------------------------------------
# Mode manuel : reproduit exactement la procedure du SDD §26.5, pas a pas.
# -----------------------------------------------------------------------------
if [[ "$MODE" == "manuel" ]]; then
  log "Mode manuel — procedure SDD §26.5, 8 etapes, confirmation a chaque etape."
  etapes=(
    "Annonce de la fenetre de maintenance (72 h a l'avance)"
    "Sauvegarde prealable complete verifiee"
    "Pull des images depuis le registry"
    "Application des migrations Prisma"
    "Redemarrage rolling avec verification des healthchecks"
    "Tests de fumee post-deploiement"
    "Communication de fin de maintenance"
    "Verification differee a T+30 min"
  )
  for i in "${!etapes[@]}"; do
    read -r -p "Etape $((i + 1))/8 — ${etapes[$i]} — executee ? [o/N] " reponse
    [[ "$reponse" == "o" ]] || erreur "Procedure interrompue a l'etape $((i + 1))."
  done
  ok "Procedure manuelle achevee."
  exit 0
fi

verifier_isolation_donnees

case "$ETAPE" in
  demarrer-green)        verifier_signature backend; verifier_signature frontend; demarrer_green ;;
  basculer)              basculer ;;
  planifier-arret-blue)  planifier_arret_blue ;;
  complet)
    [[ -n "$VERSION" ]] || erreur "--version est obligatoire."
    verifier_signature backend
    verifier_signature frontend
    if [[ "$STRATEGIE" == "blue-green" ]]; then
      demarrer_green
      "${RACINE}/scripts/tests-de-fumee.sh" --cible=green --strict
      basculer
    else
      log "Deploiement direct (strategie ${STRATEGIE})"
      CNIPAC_VERSION="$VERSION" docker compose -f "$COMPOSE_BASE" -f "${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml" up -d --wait
    fi
    ok "Deploiement ${VERSION} en ${ENVIRONNEMENT} termine."
    ;;
  *) erreur "Etape inconnue : $ETAPE" ;;
esac
