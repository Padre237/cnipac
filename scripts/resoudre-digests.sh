#!/usr/bin/env bash
# =============================================================================
# Résolution des digests d'images — ADR-023.
#
# Les fichiers du dépôt portent des digests PLACEHOLDER (sha256:0000...) : ils
# ne peuvent pas être résolus hors ligne au moment de l'écriture du socle.
# Ce script interroge les registres et les remplace par les digests réels.
#
# À EXÉCUTER AU SPRINT 1, avant le premier déploiement. La CI échoue tant que
# des placeholders subsistent en PREPROD ou en PROD.
#
# Ensuite, Renovate maintient les digests à jour (ADR-023).
# =============================================================================
set -Eeuo pipefail
RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v docker >/dev/null || { echo "docker est requis." >&2; exit 1; }

log() { printf '\033[90m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }

resoudre() {
  local reference="$1"
  docker buildx imagetools inspect "$reference" --format '{{.Manifest.Digest}}' 2>/dev/null \
    || { echo "" ; }
}

fichiers=$(grep -rl 'sha256:0\{64\}' "${RACINE}/infra" 2>/dev/null || true)
[[ -n "$fichiers" ]] || { log "Aucun digest placeholder : rien à faire."; exit 0; }

for fichier in $fichiers; do
  log "Traitement de ${fichier#$RACINE/}"
  # Extrait chaque "image:tag@sha256:000..." et résout le tag.
  while read -r reference; do
    [[ -n "$reference" ]] || continue
    nom="${reference%@*}"
    log "  résolution de ${nom}"
    digest="$(resoudre "$nom")"
    if [[ -z "$digest" ]]; then
      echo "    ÉCHEC : ${nom} introuvable. Vérifier l'accès au registre." >&2
      continue
    fi
    # Remplacement ciblé, sur la ligne portant ce nom d'image.
    sed -i.bak "s|${nom}@sha256:0\{64\}|${nom}@${digest}|g" "$fichier"
    rm -f "${fichier}.bak"
    log "    ${digest}"
  done < <(grep -oE '[a-z0-9][a-zA-Z0-9._/-]*:[a-zA-Z0-9._-]+@sha256:0{64}' "$fichier" | sort -u)
done

log "Terminé. Vérifier par : node scripts/gate-epinglage-images.mjs"
log "Puis committer : git add infra && git commit -m 'chore(infra): résoudre les digests d images'"
