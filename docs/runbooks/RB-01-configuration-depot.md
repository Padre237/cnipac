# RB-01 — Configuration initiale du dépôt et des environnements

**Quand** : Sprint 1 (SDD §29.2) · **Durée** : une demi-journée
**Prérequis** : droits d'administration sur l'organisation GitHub `cenadi-cm`

Cette procédure transforme le socle livré en dépôt opérationnel. Tant qu'elle
n'est pas achevée, les protections décrites par les ADR ne sont **pas** actives :
un ADR décrit une règle, GitHub l'applique.

---

## 1. Organisation et équipes

Créer les équipes référencées par `.github/CODEOWNERS` :

| Équipe | Membres | Zones dont elle est propriétaire |
|---|---|---|
| `cnipac-tech-leads` | Tech lead | Défaut sur tout le dépôt |
| `cnipac-architectes` | Architecte CENADI | ADR, infra, workflows, M6, M7, schéma |
| `cnipac-rssi` | RSSI CENADI | M6, conformité, secrets |
| `cnipac-dba` | Référent base de données | `apps/backend/prisma/` |
| `cnipac-metier-anc` | Référent métier ANC | Règles métier, registre des exigences |
| `cnipac-exploitation` | Exploitation CENADI | `infra/` |
| `cnipac-chef-de-projet` | Chef de projet | Licence, dérogations |

**Le dépôt reste privé** (ADR-014). Si le COPIL décide un jour de le publier,
réexaminer d'abord la configuration des runners self-hosted : un runner
self-hosted sur dépôt public permet l'exécution de code arbitraire.

## 2. Protection de la branche `main`

Settings → Branches → Add rule sur `main` :

- [x] Require a pull request before merging
  - [x] **Require approvals : 2** — SRS §14.8
  - [x] Dismiss stale approvals when new commits are pushed
  - [x] **Require review from Code Owners**
- [x] Require status checks to pass
  - Cocher **`CI verte`** — cette seule vérification suffit : elle agrège tous
    les jobs, y compris ceux sautés par les filtres de chemins.
  - Cocher également `Securite / detection-secrets` et `Securite / conformite-licences`
  - [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [x] Require signed commits
- [x] **Do not allow bypassing the above settings** — administrateurs inclus
- [ ] Allow force pushes — **décoché**
- [ ] Allow deletions — **décoché**

Settings → General → Pull Requests : **Allow squash merging uniquement**
(ADR-016). Décocher merge commits et rebase merging.

## 3. Variables et secrets d'organisation

**Variables** (Settings → Secrets and variables → Actions → Variables) :

| Nom | Valeur initiale | ADR |
|---|---|---|
| `CNIPAC_REGISTRY` | `ghcr.io` | 015 |
| `CNIPAC_IMAGE_PREFIX` | `cenadi-cm/cnipac` | 015 |
| `CNIPAC_A11Y_PAGES_BLOQUANT` | `false` jusqu'au Sprint 8 | 030 |

**Secrets** :

| Nom | Origine |
|---|---|
| `COSIGN_PRIVATE_KEY`, `COSIGN_PASSWORD` | `cosign generate-key-pair` — clé publique committée dans `infra/cosign.pub` |
| `CNIPAC_REGISTRY_TOKEN` | Jeton du registre |
| `CNIPAC_SSH_PREPROD`, `CNIPAC_SSH_PROD` | Clés de déploiement |

La clé privée cosign est **sauvegardée hors ligne par le RSSI**. Sa perte
empêcherait de signer toute nouvelle release.

## 4. Environnements GitHub

Settings → Environments.

**`preprod`** : aucun approbateur, branche `main` uniquement.

**`production`** :
- [x] **Required reviewers : 2** — c'est la porte d'approbation d'ADR-032
- [x] Wait timer : 0
- [x] Deployment branches : **tags uniquement**, motif `v*`

## 5. Runners self-hosted

Suivre [`infra/host/runner-hardening.md`](../../infra/host/runner-hardening.md).

Deux runners distincts, étiquetés :
- `self-hosted, cnipac, cenadi, preprod`
- `self-hosted, cnipac, cenadi, prod`

Un job PREPROD ne doit pas pouvoir atteindre PROD.

## 6. Résoudre les digests d'images

Le socle porte des digests placeholder, non résolubles hors ligne.

```bash
./scripts/resoudre-digests.sh
node scripts/gate-epinglage-images.mjs      # doit signaler 0 placeholder
git add infra && git commit -m "chore(infra): résoudre les digests d'images"
```

La porte d'épinglage **bloque** dès que `CNIPAC_ENV` vaut `preprod` ou `prod` :
aucun déploiement n'est possible avec des placeholders.

## 7. Provisionner les hôtes

```bash
sudo ./infra/host/bootstrap-hote.sh --role=donnees        # H2
sudo ./infra/host/bootstrap-hote.sh --role=applicatif     # H1
sudo ./infra/host/bootstrap-hote.sh --role=supervision    # H3

sudo ./scripts/bootstrap-secrets.sh
# Renseigner manuellement /srv/cnipac/secrets/kobo_token et db_url
```

**Vérifier que `/srv/cnipac` est bien une partition dédiée** (ADR-020). Le script
émet un avertissement sinon, mais ne peut pas partitionner à votre place.

## 8. Démarrer les piles, dans l'ordre

```bash
docker compose -f infra/compose/compose.data.yml up -d     # 1. données
docker compose -f infra/compose/compose.obs.yml up -d      # 2. supervision
docker compose -f infra/compose/compose.app.yml --profile blue up -d   # 3. applicatif
```

L'ordre compte : le tier applicatif attend une base disponible.

## 9. Renovate et alertes de sécurité

Installer l'application Renovate sur le dépôt (configuration : `renovate.json`).
Settings → Code security : activer Dependabot alerts et secret scanning.

## 10. Vérification finale

```bash
npm run gate:all                       # portes métier et conformité
node scripts/gate-epinglage-images.mjs
./scripts/tests-de-fumee.sh --url=https://preprod.cnipac.cm
```

Puis, sur une pull request de test : vérifier que la fusion est **refusée**
sans deux approbations. Une protection qu'on n'a pas vue refuser une fusion
n'est pas une protection vérifiée.

---

## Ce qui reste à décider

| Point | Décideur | Échéance |
|---|---|---|
| Les 5 dérogations de [DEROGATIONS.md](../DEROGATIONS.md) | COPIL | Clôture Palier 0 ; D-04 et D-05 **avant Sprint 2** |
| Existence et calendrier de `registry.cenadi.cm` | Architecte + exploitation | P3 |
| Noms de domaine et autorité de certification | Chef de projet | Sprint 3 |
| Canal de notification (Slack, Mattermost) | Tech lead | Sprint 2 |
| Instance KoboToolbox et jeton (projet de **test** distinct) | Métier ANC | Sprint 5 |
