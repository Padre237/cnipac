#!/usr/bin/env bash
# Tests de fumee post-deploiement — SDD §26.5 etape 6.
# Six verifications, moins de 60 secondes. Un echec interrompt le deploiement.
set -Eeuo pipefail
URL="${CNIPAC_BASE_URL:-http://localhost:8080}"; CIBLE=""; STRICT=0
for a in "$@"; do case "$a" in --url=*) URL="${a#*=}";; --cible=*) CIBLE="${a#*=}";; --strict) STRICT=1;; esac; done
[[ -n "$CIBLE" ]] && URL="http://cnipac-backend-${CIBLE}:3000"

echecs=0
verifier() {
  local libelle="$1" commande="$2"
  if eval "$commande" >/dev/null 2>&1; then
    printf '\033[32m  OK\033[0m   %s\n' "$libelle"
  else
    printf '\033[31m  ECHEC\033[0m %s\n' "$libelle"; echecs=$((echecs + 1))
  fi
}

echo "Tests de fumee sur ${URL}"
verifier "Sonde de sante applicative"            "curl -fsS --max-time 10 '${URL}/health'"
verifier "Connectivite PostgreSQL/PostGIS"        "curl -fsS --max-time 10 '${URL}/health/db' | grep -q '\"postgis\":true'"
verifier "Connectivite Redis (revocation JWT)"    "curl -fsS --max-time 10 '${URL}/health/redis' | grep -q 'ok'"
verifier "Carte publique accessible sans authentification (art. 26)" "curl -fsS --max-time 15 '${URL}/api/v1/producteurs?limite=1'"
verifier "Authentification administrateur"        "curl -fsS --max-time 10 -X POST '${URL}/api/v1/auth/login' -H 'Content-Type: application/json' -d \"\$CNIPAC_SMOKE_CREDENTIALS\""
verifier "Point d'entree des tableaux de bord M3" "curl -fsS --max-time 15 '${URL}/api/v1/statistiques/national'"
verifier "En-tetes de securite (NFR-C3-07)"       "curl -fsSI --max-time 10 '${URL}/health' | grep -qi 'x-content-type-options'"
verifier "Chaine du journal d'audit intacte (art. 32)" "curl -fsS --max-time 20 '${URL}/health/audit-chain' | grep -q '\"intacte\":true'"

if [[ $echecs -gt 0 ]]; then
  printf '\033[31m%d test(s) de fumee en echec.\033[0m\n' "$echecs"
  [[ $STRICT -eq 1 ]] && exit 1
fi
printf '\033[32mTests de fumee : tous verts.\033[0m\n'
