#!/usr/bin/env bash
# =============================================================================
# Rollback CNIPAC — SDD §26.8, trois mecanismes selon la gravite.
# ADR-032. Le choix du mecanisme depend de ce qui a ete touche.
# =============================================================================
set -Eeuo pipefail
RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_BASE="${RACINE}/infra/compose/docker-compose.yml"

ENVIRONNEMENT="prod"; MODE="bascule-nginx"; VERSION=""; PITR=""

for arg in "$@"; do
  case "$arg" in
    --env=*)     ENVIRONNEMENT="${arg#*=}" ;;
    --mode=*)    MODE="${arg#*=}" ;;
    --version=*) VERSION="${arg#*=}" ;;
    --pitr=*)    PITR="${arg#*=}" ;;
  esac
done

log()    { printf '\033[90m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
erreur() { printf '\033[31m[ERREUR]\033[0m %s\n' "$*" >&2; exit 1; }
ok()     { printf '\033[32m[OK]\033[0m %s\n' "$*"; }

case "$MODE" in
  # --- Mecanisme 1 : quelques SECONDES. L'ancienne version tourne encore. ---
  bascule-nginx)
    log "Rollback par bascule du reverse proxy (mecanisme 1 — secondes)"
    cible="$(cat "${RACINE}/.deploiement-couleur-cible" 2>/dev/null || echo green)"
    precedente=$([[ "$cible" == "blue" ]] && echo green || echo blue)
    if ! docker inspect "cnipac-backend-${precedente}" >/dev/null 2>&1; then
      erreur "L'instance ${precedente} n'est plus demarree. Utiliser --mode=image."
    fi
    ln -sfn "${RACINE}/infra/nginx/blue-green/upstream-${precedente}.conf" \
            "${RACINE}/infra/nginx/blue-green/upstream-actif.conf"
    docker compose -f "$COMPOSE_BASE" -f "${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml" exec -T nginx nginx -s reload
    echo "$precedente" > "${RACINE}/.deploiement-couleur-cible"
    ok "Trafic ramene sur ${precedente}."
    ;;

  # --- Mecanisme 2 : quelques MINUTES. Image anterieure conservee au registry. ---
  image)
    [[ -n "$VERSION" ]] || erreur "--version est obligatoire pour un rollback par image."
    log "Rollback par redeploiement de l'image ${VERSION} (mecanisme 2 — minutes)"
    cosign verify --key "${RACINE}/infra/cosign.pub" \
      "${CNIPAC_REGISTRY}/${CNIPAC_IMAGE_PREFIX}-backend:${VERSION}" >/dev/null \
      || erreur "Image ${VERSION} non signee : rollback refuse (ADR-024)."
    CNIPAC_VERSION="$VERSION" docker compose -f "$COMPOSE_BASE" -f "${RACINE}/infra/compose/docker-compose.${ENVIRONNEMENT}.yml" up -d --wait
    ok "Version ${VERSION} redeployee."
    ;;

  # --- Mecanisme 3 : DIZAINES DE MINUTES. Derniere extremite. ---
  base)
    log "Rollback par restauration de la base (mecanisme 3 — dizaines de minutes)"
    cat <<'AVERTISSEMENT'

  ATTENTION — restauration de la base de donnees.

  Toute donnee ecrite depuis l'instant de restauration sera perdue, y compris
  les validations d'archivistes et le journal d'audit correspondant (art. 32
  de la Loi 2024/001).

  Ce mecanisme est reserve aux cas ou une migration a corrompu des donnees.
  Il ne doit JAMAIS etre employe pour un simple defaut applicatif : utiliser
  alors --mode=bascule-nginx ou --mode=image.

  Runbook : docs/runbooks/RB-03-rollback.md

AVERTISSEMENT
    read -r -p "Confirmer la restauration en toutes lettres (taper RESTAURER) : " confirmation
    [[ "$confirmation" == "RESTAURER" ]] || erreur "Restauration annulee."
    "${RACINE}/scripts/restaurer.sh" --cible="$ENVIRONNEMENT" ${PITR:+--pitr="$PITR"}
    ok "Base restauree. Verifier la chaine du journal d'audit avant reouverture du service."
    "${RACINE}/scripts/verifier-chaine-audit.sh"
    ;;

  *) erreur "Mode inconnu : $MODE (bascule-nginx | image | base)" ;;
esac

"${RACINE}/scripts/journal-deploiement.sh" --rollback --mode="$MODE" --version="${VERSION:-NA}"
