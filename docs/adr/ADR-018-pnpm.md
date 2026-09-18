# ADR-018 — npm, conformement au SDD §26.4

- **Statut** : **REVISE — derogation retiree**, le SDD fait foi
- **Date** : 2026-09-17
- **Decideur** : tech lead
- **Perimetre** : technique
- **Exigences concernees** : NFR-C5-05, NFR-C9-03, NFR-C6-01

> **Cet ADR est ANNULE.** La derogation proposant pnpm est **retiree** sur
> instruction du maitre d'ouvrage.
>
> **Decision retenue : npm**, avec `npm ci` et les workspaces npm, exactement
> comme l'ecrit le SDD §26.4.
>
> Le risque de dependance fantome evoque dans la version initiale du present ADR
> subsiste ; il est desormais traite par la revue de code et par le controle des
> licences, non par l'outillage. Ce point est signale au COPIL pour information,
> sans demande de derogation.

---

_Le texte qui suit est conserve a titre de trace de l'analyse initiale._

## Contexte

Le SDD §26.4 ecrit `npm ci` dans le workflow d'exemple. Le choix d'un gestionnaire de
paquets n'y fait l'objet d'aucune justification : c'est une valeur par defaut, pas une
decision argumentee.

Le passage au monorepo (ADR-013) change la donne. npm applique un **hoisting** des
dependances a la racine de `node_modules` : une application peut alors importer un paquet
qu'elle n'a jamais declare, parce qu'il se trouve etre une dependance transitive d'une autre
application du workspace. Ces « dependances fantomes » cassent silencieusement le jour ou la
dependance intermediaire change de version. Sur un systeme qui doit etre
**integralement reconstructible a partir du seul depot** (NFR-C5-05), c'est un risque
structurel, pas un detail de confort.

## Decision

**pnpm 9.x**, avec `node-linker=isolated` (defaut pnpm) : chaque paquet ne voit que les
dependances qu'il declare. Une dependance fantome devient une erreur de compilation, en
local comme en CI.

- Version epinglee via `corepack` et le champ `packageManager` du `package.json` racine :
  aucune installation manuelle, la bonne version est activee automatiquement.
- `frozen-lockfile=true` dans `.npmrc` : une installation dont le lockfile n'est pas a jour
  echoue. Le lockfile devient contractuel.
- Licence pnpm : MIT — conforme a NFR-C9-03.

## Consequences

**Positives**

- Dependances fantomes rendues impossibles : le graphe de dependances declare est le graphe
  reel. C'est la condition de la reconstructibilite NFR-C5-05.
- Installations CI nettement plus rapides grace au magasin adressable par contenu, et
  empreinte disque reduite sur des runners CENADI aux ressources contraintes (§8.3).
- Gestion native des workspaces, avec filtrage par paquet (`pnpm --filter`).

**Negatives / couts**

- Ecart documentaire avec le SDD §26.4, a valider par le COPIL.
- Delta d'apprentissage pour l'equipe (critere C-04 du SDD §4.1). Evalue a **une demi-journee** :
  les commandes usuelles sont homonymes (`pnpm install`, `pnpm run`, `pnpm add`). Un
  memo est fourni dans `docs/conventions/DEVELOPPEMENT.md`.
- Quelques outils anciens supposent un `node_modules` aplati. Aucun n'est present dans la
  stack retenue ; le cas echeant, `public-hoist-pattern` permet une exception ciblee et
  documentee.

**Irreversibilite** — Faible. Un retour a npm consiste a supprimer le lockfile, regenerer,
ajuster trois fichiers de configuration et corriger les dependances fantomes que pnpm aura
justement empeche d'apparaitre. Une demi-journee.

## Alternatives ecartees

| Alternative      | Raison du rejet                                                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| npm workspaces   | Hoisting par defaut, donc dependances fantomes possibles. Installations plus lentes. Aucun avantage compensatoire.                    |
| Yarn Berry (PnP) | Rupture de compatibilite plus forte avec l'outillage (debogueurs, editeurs). Delta d'apprentissage superieur pour un gain equivalent. |
| Bun              | Ne satisfait pas le critere C-02 du SDD §4.1 (maturite). Ecosysteme NestJS insuffisamment eprouve pour un systeme d'Etat.             |

## Mise en oeuvre

`package.json` (champ `packageManager`), `pnpm-workspace.yaml`, `.npmrc`,
`corepack enable` dans les workflows, `docs/conventions/DEVELOPPEMENT.md`.
