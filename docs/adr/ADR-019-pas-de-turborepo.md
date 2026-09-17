# ADR-019 — N'introduire aucun orchestrateur de monorepo en P1

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : tech lead
- **Perimetre** : technique
- **Exigences concernees** : principe de simplicite maitrisee (SDD §2.1.1), NFR-C6-05

## Contexte

Le choix du monorepo (ADR-013) amene naturellement la question d'un orchestrateur de taches
avec cache distribue : Turborepo, Nx, Moon. Ces outils apportent un gain reel — mais sur des
monorepos de dizaines de paquets et des equipes de dizaines de developpeurs.

CNIPAC compte **quatre paquets** et **quatre developpeurs**. Le SDD §4 pose explicitement la
regle : « toute brique additionnelle doit produire son ticket d'entree sous forme d'exigence
a couvrir ». Aucune exigence du SRS ni du SDD ne justifie un orchestrateur.

## Decision

Aucun orchestrateur. L'ordonnancement repose sur trois mecanismes deja disponibles :

1. `pnpm -r` et `pnpm --filter` pour l'execution recursive ou ciblee ;
2. les `jobs` et la matrice GitHub Actions pour le parallelisme en CI ;
3. `dorny/paths-filter` pour ne reconstruire que ce qui a change.

Le cache de dependances est assure par `actions/setup-node` sur le magasin pnpm.

**Condition de reexamen** : si le temps d'execution de `ci.yml` depasse **12 minutes** en
moyenne sur 20 executions consecutives, la decision est rouverte par un ADR successeur. Ce
seuil est mesure automatiquement par le workflow `hygiene.yml`, qui publie la duree moyenne
dans le resume de job.

## Consequences

**Positives** — Une dependance de moins a maintenir, a auditer et a inclure dans le SBOM.
Un nouvel arrivant lit un `package.json` et comprend la chaine de construction sans
apprendre un outil supplementaire.

**Negatives / couts** — Pas de cache distribue : un job CI recompile ce qu'un autre a deja
compile. Sur un perimetre a quatre paquets, le cout mesure est de l'ordre de la minute.
Le jour ou il ne le sera plus, le seuil declenche la reouverture.

**Irreversibilite** — Nulle. Turborepo s'ajoute en une demi-journee sans rien reecrire.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| Turborepo | Gain negligeable a 4 paquets. Le cache distribue implique un service externe supplementaire ou un stockage a exploiter. |
| Nx | Beaucoup plus intrusif (generateurs, plugins, conventions imposees). Contraire au principe de simplicite maitrisee. |

## Mise en oeuvre

`package.json` racine (scripts `pnpm -r`), `.github/workflows/ci.yml` (matrice et filtres de
chemins), `.github/workflows/hygiene.yml` (mesure du seuil de 12 minutes).
