# Mise en place du dépôt — procédure complète

De zéro à un système déployé. Durée : **une demi-journée** pour les parties 1 à 4
(faisables aujourd'hui, sans rien attendre), **une journée** pour les parties 5 à 7
(qui dépendent de l'infrastructure CENADI).

---

# Partie A — Ce dont vous avez besoin

## A.1 — Sur votre poste, maintenant

| Outil | Version | Vérifier | Installer (macOS) |
|---|---|---|---|
| Node.js | **22 LTS** | `node -v` | `brew install node@22` |
| npm | ≥ 10 | `npm -v` | fourni avec Node |
| Docker Desktop | ≥ 24 | `docker -v` | `brew install --cask docker` |
| Docker Compose | v2 | `docker compose version` | fourni avec Docker Desktop |
| Git | ≥ 2.40 | `git --version` | `brew install git` |
| GitHub CLI | ≥ 2.40 | `gh --version` | `brew install gh` |
| cosign | ≥ 2.0 | `cosign version` | `brew install cosign` |
| age | ≥ 1.1 | `age --version` | `brew install age` |
| syft *(optionnel)* | ≥ 1.0 | `syft version` | `brew install syft` |

`cosign` et `age` ne servent qu'au déploiement : vous pouvez démarrer sans eux.

## A.2 — Comptes et accès

| Élément | Qui le fournit | Bloquant pour |
|---|---|---|
| Organisation GitHub `cenadi-cm` + droits admin | DSI / CENADI | tout (partie B) |
| Plan GitHub Team ou Enterprise | CENADI | environnements avec approbateurs |
| Compte Codecov relié au dépôt | vous (gratuit) | job `couverture` de la CI (SDD §26.4) |
| Compte Docker Hub *(optionnel)* | vous | éviter la limite de tirage anonyme |

## A.3 — Infrastructure CENADI

| Élément | Spécification (SDD §8.3) | Bloquant pour |
|---|---|---|
| Hôte **H1** applicatif | 4 vCPU, 8 Go, 100 Go SSD, Ubuntu LTS | déploiement PREPROD/PROD |
| Hôte **H2** données | 4 vCPU, 16 Go, 500 Go SSD | idem |
| Hôte **H3** supervision | 2 vCPU, 4 Go, 1 To | supervision, sauvegardes |
| Site de reprise | 2 To, accès SSH | externalisation des sauvegardes |
| Accès SSH, utilisateur dédié, clé publique déposée | — | déploiement automatisé |
| IP publique fixe + FQDN | `cnipac.cm`, `preprod.cnipac.cm` | TLS, recette |
| Certificats TLS | Let's Encrypt ou PKI souveraine | HTTPS (NFR-C3-01) |
| Ports 80 et 443 ouverts en entrée sur H1 uniquement | SDD §8.4 | accès public |

> **En attendant, rien ne bloque.** Le SDD §29.7.3 prévoit explicitement
> « un environnement de DEV temporaire sur poste local ». C'est la partie C
> ci-dessous, faisable immédiatement.

## A.4 — Métier

| Élément | Qui | Bloquant pour |
|---|---|---|
| Instance KoboToolbox + `asset_uid` du formulaire | ANC | module M1 |
| Jeton API Kobo d'un projet **de test** | ANC | ingestion en DEV et PREPROD |
| Jeton API Kobo de production | ANC | ingestion en PROD |
| Liste des 200 producteurs géolocalisés | ANC / agent de collecte | **AC-P1-03** |
| Référents nommés pour les 7 équipes GitHub | chef de projet | CODEOWNERS, revues |

## A.5 — Secrets à produire

| Secret | Production | Où |
|---|---|---|
| `db_password`, `redis_password`, `jwt_secret` | `scripts/bootstrap-secrets.sh` | `/srv/cnipac/secrets/` |
| Paire de clés `age` (sauvegardes) | `age-keygen -o cle_privee` | clé privée **hors de l'hôte sauvegardé** |
| Paire de clés `cosign` | `cosign generate-key-pair` | privée → secret GitHub ; publique → `infra/cosign.pub` |
| Clés SSH de déploiement | `ssh-keygen -t ed25519` | privée → secret GitHub ; publique → `authorized_keys` |
| `CODECOV_TOKEN` | interface Codecov | secret GitHub |

---

# Partie B — Créer le dépôt GitHub (30 minutes)

```bash
cd /Users/imacpro/Desktop/CNIPAC_V2

git add -A
git commit -m "chore(infra): socle technique, pipeline CI/CD et conventions

Palier 0 du plan de sprints (SDD §29.2). Conforme au SRS V2.0 et au SDD V4.0.

Refs: CNIPAC-1"

gh repo create cenadi-cm/cnipac --private --source=. --remote=origin
git push -u origin main
```

## B.1 — Équipes

```bash
for equipe in tech-leads architectes rssi dba metier-anc exploitation chef-de-projet; do
  gh api orgs/cenadi-cm/teams -f name="cnipac-$equipe" -f privacy=closed
done
```

Puis y ajouter les personnes. Ces équipes sont référencées par
`.github/CODEOWNERS` : tant qu'elles n'existent pas, les revues obligatoires ne
s'appliquent pas.

## B.2 — Protection de `main`

Interface GitHub → Settings → Branches → Add rule sur `main` :

- ☑ Require a pull request before merging
  - ☑ **Require approvals : 2** *(SRS §14.8)*
  - ☑ Dismiss stale pull request approvals when new commits are pushed
  - ☑ Require review from Code Owners
- ☑ Require status checks to pass before merging
  - Cocher **`CI verte`** — cette seule vérification agrège tous les jobs
  - Cocher `Securite / detection-secrets` et `Securite / conformite-licences`
  - ☑ Require branches to be up to date before merging
- ☑ Require conversation resolution before merging
- ☑ Require signed commits
- ☑ **Do not allow bypassing the above settings**
- ☐ Allow force pushes — **décoché**
- ☐ Allow deletions — **décoché**

Settings → General → Pull Requests : **Allow squash merging uniquement**.

## B.3 — Variables et secrets d'organisation

```bash
gh variable set CNIPAC_REGISTRY        --body "ghcr.io"            --org cenadi-cm
gh variable set CNIPAC_IMAGE_PREFIX    --body "cenadi-cm/cnipac"   --org cenadi-cm
gh variable set CNIPAC_A11Y_PAGES_BLOQUANT --body "false"          --org cenadi-cm

cosign generate-key-pair
gh secret set COSIGN_PRIVATE_KEY --body "$(cat cosign.key)" --org cenadi-cm
gh secret set COSIGN_PASSWORD    --org cenadi-cm            # saisie interactive
mv cosign.pub infra/cosign.pub && rm cosign.key             # la privée ne reste PAS sur disque

gh secret set CODECOV_TOKEN --org cenadi-cm                 # SDD §26.4
```

> La clé privée cosign doit être **sauvegardée hors ligne par le RSSI**.
> Sa perte empêche de signer toute release ultérieure.

## B.4 — Environnements

Settings → Environments.

**`preprod`** : aucun approbateur, branche de déploiement `main` uniquement.

**`production`** :
- ☑ **Required reviewers : 2** — c'est la porte d'approbation du SDD §26.4
- Deployment branches : **Protected tags only**, motif `v*`

Puis :

```bash
gh secret set CNIPAC_SSH_PREPROD --env preprod    --body "$(cat ~/.ssh/cnipac_preprod)"
gh secret set CNIPAC_SSH_PROD    --env production --body "$(cat ~/.ssh/cnipac_prod)"
```

## B.5 — Renovate et alertes

- Installer l'application **Renovate** sur le dépôt (configuration : `renovate.json`)
- Settings → Code security : activer **Dependabot alerts** et **Secret scanning**

---

# Partie C — Environnement de développement local (20 minutes)

**Faisable aujourd'hui, sans infrastructure CENADI.**

```bash
npm ci                        # installe le monorepo et crée package-lock.json
cp .env.example .env

# Piles : base commune + override DEV (SDD §26.3)
docker compose -f infra/compose/docker-compose.yml \
               -f infra/compose/docker-compose.dev.yml up -d postgres redis

docker compose -f infra/compose/docker-compose.yml \
               -f infra/compose/docker-compose.dev.yml ps    # attendre "healthy"

npx -w @cnipac/backend prisma migrate dev --name socle_initial
npx -w @cnipac/backend prisma db seed

npm run start:dev -w @cnipac/backend    # http://localhost:3000
npm run dev -w @cnipac/frontend         # http://localhost:5173
```

Vérifier : `curl http://localhost:3000/health` et `http://localhost:3000/api/docs`.

## C.1 — Vérifier que les portes fonctionnent

```bash
npm run lint && npm run typecheck && npm run test:unit
npm run gate:all
node scripts/gate-coherence-versions.mjs
node scripts/gate-epinglage-images.mjs
```

## C.2 — Résoudre les digests d'images

Les fichiers portent des digests de substitution (`sha256:0000…`) : ils ne
peuvent pas être résolus hors ligne.

```bash
./scripts/resoudre-digests.sh
node scripts/gate-epinglage-images.mjs          # doit signaler 0 substitut
git add infra && git commit -m "chore(infra): résoudre les digests d'images"
```

La porte **bloque** dès que `CNIPAC_ENV` vaut `preprod` ou `prod` : aucun
déploiement n'est possible tant qu'il reste des substituts.

---

# Partie D — Vérifier la CI (15 minutes)

```bash
git checkout -b feat/CNIPAC-1-verifier-pipeline
echo "" >> README.md
git commit -am "docs(docs): vérifier le pipeline

Refs: CNIPAC-1"
git push -u origin feat/CNIPAC-1-verifier-pipeline
gh pr create --fill
gh pr checks --watch
```

**Ce que vous devez observer** :

| Workflow | Attendu |
|---|---|
| `CI` | vert — lint, typage, tests, couverture, traçabilité, build |
| `Securite` | vert — gitleaks, npm audit, Trivy, CodeQL, licences |
| `Portes de qualite` | vert — a11y, budget de bundle, contrat d'API |
| `Tests E2E` | vert ou sauté tant qu'il n'y a pas d'écrans |
| `Hygiene` | vert — titre de PR conforme |

Puis **tenter de fusionner sans approbation** : GitHub doit refuser. Une
protection qu'on n'a jamais vue refuser une fusion n'est pas une protection
vérifiée.

---

# Partie E — Provisionner les hôtes CENADI (2 heures)

Dès que les accès SSH sont disponibles.

```bash
scp -r infra/ scripts/ cnipac@h1.cenadi.cm:/srv/cnipac/
ssh cnipac@h1.cenadi.cm

sudo /srv/cnipac/infra/host/bootstrap-hote.sh --role=applicatif
sudo /srv/cnipac/scripts/bootstrap-secrets.sh

# Secrets provenant de tiers, à renseigner à la main :
sudo vi /srv/cnipac/secrets/kobo_token
sudo vi /srv/cnipac/secrets/db_url

# Clé de chiffrement des sauvegardes (SDD §4.4)
age-keygen -o /srv/cnipac/secrets/cle_privee_sauvegardes
age-keygen -y /srv/cnipac/secrets/cle_privee_sauvegardes \
  > /srv/cnipac/secrets/cle_publique_sauvegardes
```

> **La clé privée `age` doit être copiée hors de l'hôte et supprimée du site
> sauvegardé.** Une clé stockée à côté des sauvegardes qu'elle protège ne
> protège rien.

Certificats TLS :

```bash
sudo certbot certonly --webroot -w /srv/cnipac/acme \
  -d cnipac.cm -d www.cnipac.cm
sudo cp /etc/letsencrypt/live/cnipac.cm/fullchain.pem /srv/cnipac/certs/cnipac.cm.fullchain.pem
sudo cp /etc/letsencrypt/live/cnipac.cm/privkey.pem  /srv/cnipac/certs/cnipac.cm.key.pem
```

Sauvegarde quotidienne (SDD §27.4, NFR-C2-05) :

```bash
sudo crontab -e
# 0 2 * * * /srv/cnipac/infra/backup/sauvegarde-quotidienne.sh >> /var/log/cnipac-sauvegarde.log 2>&1
```

Runner GitHub self-hosted : suivre `infra/host/runner-hardening.md`.

---

# Partie F — Premier déploiement (1 heure)

## F.1 — PREPROD

```bash
git tag -s v0.1.0-alpha.1 -m "Socle technique — première mise en service PREPROD"
git push origin v0.1.0-alpha.1
```

Le workflow `Release` construit, produit le SBOM, signe et publie les images.
`CD PREPROD` déploie automatiquement.

Sur l'hôte, en mode manuel si besoin :

```bash
docker compose -f infra/compose/docker-compose.yml \
               -f infra/compose/docker-compose.preprod.yml pull
docker compose -f infra/compose/docker-compose.yml \
               -f infra/compose/docker-compose.preprod.yml up -d

./scripts/tests-de-fumee.sh --url=https://preprod.cnipac.cm
```

## F.2 — PRODUCTION

Procédure du SDD §26.5, déclenchée par un opérateur autorisé avec approbation
explicite (SDD §26.4) :

```bash
gh workflow run cd-prod.yml \
  -f version=v0.1.0 \
  -f strategie=blue-green \
  -f motif="Mise en service initiale — recette P1"
```

Deux approbateurs valident, puis la séquence s'exécute : sauvegarde vérifiée,
migrations, démarrage, tests de fumée, bascule, observation.

En mode dégradé (GitHub Actions indisponible) :

```bash
./scripts/deploy.sh --env=prod --mode=manuel    # les 8 étapes du SDD §26.5, pas à pas
```

---

# Partie G — Ordre de bataille

| Priorité | Action | Bloqué par | Quand |
|---|---|---|---|
| 1 | **Escalader la demande d'hôtes H1/H2/H3** | rien | aujourd'hui |
| 2 | **Lancer le chantier des 200 producteurs** | rien | aujourd'hui |
| 3 | **Demander le jeton Kobo de test aux ANC** | rien | aujourd'hui |
| 4 | Parties B, C, D | rien | aujourd'hui |
| 5 | Schéma Prisma + chaîne d'audit | partie C | J+1 à J+3 |
| 6 | Partie E | accès SSH | dès réception |
| 7 | Partie F | parties E et 5 | semaine 4 |

Les trois premières lignes ne coûtent qu'un courriel chacune et conditionnent
tout le reste. **Les envoyer avant d'écrire la première ligne de code.**
