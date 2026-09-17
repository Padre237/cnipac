#!/usr/bin/env bash
# Generation des secrets sur l'hote — ADR-033.
# Les valeurs ne sont JAMAIS affichees ni transmises par un canal de l'equipe.
set -Eeuo pipefail
DEST="${1:-/srv/cnipac/secrets}"
umask 077
mkdir -p "$DEST"

generer() {
  local nom="$1" longueur="${2:-32}"
  if [[ -f "${DEST}/${nom}" ]]; then
    echo "  ${nom} : deja present, conserve (utiliser rotation-secrets.sh pour le renouveler)"
    return
  fi
  openssl rand -base64 "$longueur" | tr -d '\n' > "${DEST}/${nom}"
  chmod 0400 "${DEST}/${nom}"
  echo "  ${nom} : genere (${longueur} octets d'entropie)"
}

echo "Generation des secrets dans ${DEST}"
generer db_password 32
generer redis_password 32
generer jwt_secret 48          # RFC 7519 : marge confortable au-dela du minimum
generer cle_chiffrement_sauvegardes 32   # NFR-C3-02, chiffrement at-rest

# Secrets a renseigner manuellement : ils proviennent de tiers.
for manuel in kobo_token db_url; do
  if [[ ! -f "${DEST}/${manuel}" ]]; then
    touch "${DEST}/${manuel}"; chmod 0400 "${DEST}/${manuel}"
    echo "  ${manuel} : fichier vide cree — A RENSEIGNER MANUELLEMENT"
  fi
done

chown -R root:root "$DEST" 2>/dev/null || true
echo
echo "Termine. Rappels :"
echo "  - aucun secret ne doit transiter par courriel, messagerie ou ticket ;"
echo "  - rotation : 90 jours pour les secrets applicatifs (runbook RB-07) ;"
echo "  - sauvegarder la cle de chiffrement des sauvegardes HORS de l'hote sauvegarde."
