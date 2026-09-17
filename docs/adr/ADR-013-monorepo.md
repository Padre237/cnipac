# ADR-013 — Adopter un monorepo en workspaces npm

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI
- **Perimetre** : technique
- **Exigences concernees** : NFR-C6-02, NFR-C6-05, NFR-C5-05

## Contexte

Le SDD V4.0 decrit un backend NestJS (§7) et un frontend React (§20) comme deux artefacts
distincts. Le plan de sprints (§29.2, Sprint 1) mentionne « setup depotS Git » au pluriel,
sans trancher. Trois elements du dossier de conception imposent pourtant un couplage fort
entre les deux applications :

1. Les types des DTO sont dupliques cote front (`shared/types/ — DTO miroirs`, §20.2) ;
2. Les schemas de validation Zod sont explicitement decrits comme « reutilisables cote
   backend » (§4.3) ;
3. Les regles de gestion (RG-Mx-yy) et les enumerations metier (statuts de fiche, 8 roles
   RBAC, 9 reseaux archivistiques, 10 regions) doivent etre **strictement identiques** des
   deux cotes, sous peine de divergence silencieuse du referentiel.

Avec deux depots, ces trois elements se synchronisent a la main. L'experience montre que
cette synchronisation echoue au bout de quelques sprints, et que la divergence se manifeste
en production sous forme d'incoherences de statut.

## Decision

Un **depot unique** `cnipac`, organise en workspaces npm (SDD §26.4) :

```
apps/backend           @cnipac/backend      API NestJS
apps/frontend          @cnipac/frontend     PWA React
packages/shared-types  @cnipac/shared-types Enumerations metier, DTO, schemas Zod
packages/tsconfig      @cnipac/tsconfig     Configurations TypeScript de base
packages/eslint-config @cnipac/eslint-config Regles de lint partagees
infra/                 Compose, Dockerfiles, Nginx, monitoring, sauvegardes
docs/                  ADR, runbooks, regles metier, tracabilite, references
tests/                 E2E Playwright, charge k6, securite
scripts/               Portes de qualite et outillage
```

`packages/shared-types` est **l'unique source de verite** des enumerations metier. Toute
regle de gestion exprimable comme une constante y est declaree une seule fois et consommee
par les deux applications.

## Consequences

**Positives**

- Une PR qui modifie un contrat d'API modifie le front et le back dans le meme commit :
  la CI detecte la rupture immediatement, pas trois jours plus tard.
- La matrice de tracabilite (chap. 30 du SDD) est unique et verifiable en un seul point.
- Un `git clone` unique donne l'environnement complet — repond a l'objectif du SDD §4
  (« cloner le depot, lancer une commande, environnement fonctionnel en 15 minutes »).
- La reconstruction integrale exigee par NFR-C5-05 part d'une seule reference.

**Negatives / couts**

- Les droits d'acces sont grossiers : qui peut lire le front peut lire le back. Acceptable
  ici, les deux equipes etant la meme equipe CENADI.
- La CI doit filtrer par chemin pour ne pas tout reconstruire a chaque commit. Traite par
  les `paths-filter` des workflows.
- Le depot croit plus vite ; les maquettes Stitch (`docs/design/`) et les documents de
  reference pesent deja plusieurs dizaines de Mo.

**Irreversibilite** — Faible. Une extraction ulterieure en depots separes via
`git subtree split` conserve l'historique. Cout estime : 1 a 2 jours.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| Deux depots + package npm partage publie | Impose une chaine de publication de package pour une equipe de 4 personnes. Cout d'exploitation sans contrepartie. |
| Deux depots + duplication manuelle des types | Divergence garantie a moyen terme. Incompatible avec la coherence exigee du referentiel national. |
| Monorepo avec git submodules | Complexite operationnelle notoire, mauvaise ergonomie pour les nouveaux arrivants (critere C-04 du SDD §4.1). |

## Mise en oeuvre

`package.json` racine (champ `workspaces`), `packages/shared-types/`,
filtres de chemins dans `.github/workflows/ci.yml`.
