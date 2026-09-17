#!/usr/bin/env bash
# =============================================================================
# Provisionnement d'un hote CNIPAC — ADR-020, ADR-033.
# Ce qui reste hors conteneur : pare-feu, durcissement SSH, mises a jour de
# securite, partition de donnees, droits POSIX. Le reste est conteneurise.
# Idempotent : peut etre rejoue sans effet de bord.
#
# Usage : sudo ./bootstrap-hote.sh --role=applicatif|donnees|supervision
# =============================================================================
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Ce script doit etre execute en root." >&2; exit 1; }

ROLE="applicatif"
for a in "$@"; do case "$a" in --role=*) ROLE="${a#*=}";; esac; done

log() { printf '\033[90m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }

log "[1/7] Mises a jour de securite automatiques"
apt-get update -qq
apt-get install -y -qq unattended-upgrades apt-listchanges
dpkg-reconfigure -f noninteractive unattended-upgrades

log "[2/7] Arborescence CNIPAC"
# Les donnees PostgreSQL et Redis vivent dans des volumes Docker nommes
# (SDD §26.3). /srv/cnipac porte les secrets, les certificats et les sauvegardes.
mkdir -p /srv/cnipac/{sauvegardes,secrets,certs,acme,journaux,infra}

log "[3/7] Droits POSIX"
chmod 0700 /srv/cnipac/secrets
chmod 0750 /srv/cnipac/sauvegardes

log "[4/7] Pare-feu — SDD §8.4 : point d'entree unique sur 443"
apt-get install -y -qq ufw
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw limit 22/tcp comment 'SSH avec limitation de debit'
if [[ "$ROLE" == "applicatif" ]]; then
  ufw allow 80/tcp  comment 'HTTP — redirection et ACME uniquement'
  ufw allow 443/tcp comment 'HTTPS — point d entree unique'
fi
# Les tiers donnees et supervision ne sont joignables que depuis le reseau interne.
ufw --force enable

log "[5/7] Durcissement SSH"
install -m 0644 /dev/stdin /etc/ssh/sshd_config.d/99-cnipac.conf <<'SSHCONF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowGroups cnipac-exploitation
SSHCONF
systemctl reload ssh || systemctl reload sshd

log "[6/7] Parametres noyau pour PostgreSQL"
install -m 0644 /dev/stdin /etc/sysctl.d/99-cnipac.conf <<'SYSCTL'
# Eviter que l'OOM killer ne s'en prenne au postmaster (ADR-020 point 5).
vm.overcommit_memory = 2
vm.overcommit_ratio = 90
vm.swappiness = 1
# Ecriture differee : evite les a-coups d'E/S sur SSD.
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
# Charge reseau (NFR-C1-03 : 200 utilisateurs simultanes).
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
SYSCTL
sysctl -p /etc/sysctl.d/99-cnipac.conf >/dev/null

log "[7/7] Docker et fuseau horaire"
timedatectl set-timezone Africa/Douala      # NFR-C8-03
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh
install -m 0644 /dev/stdin /etc/docker/daemon.json <<'DOCKERCONF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "5" },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
DOCKERCONF
systemctl restart docker

echo
log "Provisionnement termine (role : ${ROLE})."
echo "Etapes suivantes :"
echo "  1. ./scripts/bootstrap-secrets.sh          # generer les secrets (ADR-033)"
echo "  2. renseigner /srv/cnipac/secrets/kobo_token et db_url"
echo "  3. deposer les certificats dans /srv/cnipac/certs"
echo "  4. docker compose -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.prod.yml up -d"
echo "  5. runbook docs/runbooks/RB-01-configuration-depot.md"
