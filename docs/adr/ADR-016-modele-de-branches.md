# ADR-016 — Trunk-based avec branches courtes et releases par tag

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : tech lead
- **Perimetre** : technique
- **Exigences concernees** : SRS §14.8, NFR-C6-02

## Contexte

Le SRS §14.8 prescrit « un workflow Git de type Trunk-Based avec branches feature courtes »,
`main` protegee, **2 reviewers**, tags signes, correctifs sur `hotfix/*`. Mais le workflow
d'exemple du SDD §26.4 declenche la construction des images sur `release/*` — ce qui releve
d'un modele GitFlow, incompatible avec le trunk-based. **Les deux documents se
contredisent.** Il faut trancher.

## Decision

Trunk-based strict. La contradiction est levee en faveur du SRS, document de rang
superieur, et les branches `release/*` sont supprimees du modele.

| Branche / ref               | Duree de vie             | Origine     | Destination                         |
| --------------------------- | ------------------------ | ----------- | ----------------------------------- |
| `main`                      | permanente, **protegee** | —           | —                                   |
| `feat/<ticket>-<slug>`      | **72 h maximum**         | `main`      | `main` via PR                       |
| `fix/<ticket>-<slug>`       | 72 h maximum             | `main`      | `main` via PR                       |
| `hotfix/<ticket>-<slug>`    | < 24 h                   | tag de PROD | `main` via PR, deploiement accelere |
| `vX.Y.Z` (tag annote signe) | permanente               | `main`      | declenche `release.yml`             |

**Protection de `main`** (a configurer dans GitHub, procedure dans
`docs/runbooks/RB-01-configuration-depot.md`) :

- 2 approbations obligatoires (SRS §14.8), dont au moins un CODEOWNER ;
- tous les controles de `ci.yml` et `security.yml` au vert ;
- branche a jour avec `main` avant fusion ;
- conversations resolues ;
- **fusion en squash uniquement** — un ticket, un commit sur `main`, historique lisible ;
- push force interdit, suppression interdite, y compris pour les administrateurs.

**Limite des 72 heures** : une branche de plus de 72 heures est signalee automatiquement
par le workflow `hygiene.yml`. Ce n'est pas bloquant, c'est un signal : une branche longue
annonce un ticket mal decoupe, pas un developpeur lent.

**Versions** conformes au SRS §14.8 : P1 = `v0.1.0`, P2 = `v0.5.0`, P3 = `v1.0.0`.
Entre les jalons, semver strict. Avant P1, pre-releases `v0.1.0-alpha.N`.

**Tags signes** (GPG ou SSH). La verification de signature est un controle bloquant du
workflow `release.yml` : une release non signee n'est pas construite.

## Consequences

**Positives** — Integration continue reelle : pas de branche divergente, pas de fusion
douloureuse. Le tag est le seul declencheur de release, ce qui rend la question « qu'est-ce
qui tourne en production ? » verifiable en une commande : `docker inspect` donne le digest,
le digest donne le tag, le tag donne le commit.

**Negatives / couts** — Exige une discipline de decoupage des tickets que l'equipe devra
acquerir. Impose des feature flags pour toute fonctionnalite dont le developpement depasse
72 heures ; un module `FeatureFlagModule` minimal est prevu au socle backend.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                       | Raison du rejet                                                                                                                                    |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| GitFlow (`develop` + `release/*`) | Contraire au SRS §14.8. Produit des fusions longues et des correctifs a repercuter sur plusieurs branches — precisement ce que le SRS veut eviter. |
| Fusion en merge commit            | Historique illisible sur un projet a 20 sprints. Complique le `git bisect` lors des incidents.                                                     |
| Rebase et fast-forward            | Equivalent fonctionnel au squash mais plus exigeant pour une equipe qui decouvre le trunk-based.                                                   |

## Mise en oeuvre

`.github/CODEOWNERS`, `.github/workflows/hygiene.yml`, `docs/runbooks/RB-01-configuration-depot.md`,
`docs/conventions/GIT.md`.
