# ADR-036 — Imposer Conventional Commits et generer le changelog

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : tech lead
- **Perimetre** : technique
- **Exigences concernees** : SRS §14.8 (note de version), SDD §4.5, NFR-C6-02, NFR-C6-04

## Contexte

Le SDD §4.5 retient « Commitlint + Conventional Commits » pour la « generation automatique du
changelog, tracabilite des evolutions », et Husky + lint-staged pour les hooks de pre-commit.
Le SRS §14.8 exige une note de version a chaque release majeure. Aucun document ne precise
les types ni les portees admis, ni ce qui se passe en cas de non-respect.

Sur un systeme d'Etat destine a etre repris par une autre equipe dans dix ans (objectif du
SDD §4), l'historique Git est une piece de documentation a part entiere. Un historique de
« fix », « wip », « update » n'en est pas une.

## Decision

**1. Format impose**, verifie par commitlint au hook `commit-msg` **et** en CI sur le titre
de chaque PR — la CI est la barriere reelle, un hook local pouvant etre contourne.

```
<type>(<portee>): <sujet>
```

**Types** : `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
`chore`, `revert`.

**Portees** alignees sur la decomposition fonctionnelle du SRS chapitre 5 : `m1` a `m7`,
plus `backend`, `frontend`, `shared`, `db`, `infra`, `ci`, `docs`, `deps`, `security`,
`i18n`, `a11y`, `release`. La portee n'est pas decorative : elle permet de reconstituer
l'effort par module, information utile aux rapports d'avancement du COPIL.

**2. Reference de ticket obligatoire** dans le corps du commit (`Refs: CNIPAC-123`), sauf
pour `chore` et `docs`.

**3. Rupture de compatibilite** signalee par `!` ou un pied `BREAKING CHANGE:`. Sur un
systeme exposant une API publique versionnee (M7, FR-M7-08), une rupture non signalee est un
defaut de livraison.

**4. Changelog genere** par `git-cliff` a chaque tag, regroupe par module fonctionnel plutot
que par type technique — un archiviste des ANC lisant la note de version doit y trouver
« Module M4 — Gestion des producteurs », pas « refactor ».

**5. Le titre de la PR devient le message de commit**, la fusion se faisant en squash
(ADR-016). C'est donc le titre de la PR qui est verifie.

## Consequences

**Positives** — Le changelog exige par le SRS §14.8 est produit sans redaction manuelle.
L'historique reste lisible pour l'equipe de maintenance. `git log --grep "(m6)"` donne
l'historique complet d'un module en une commande.

**Negatives / couts** — Friction initiale de quelques jours. Les messages en francais sont
autorises ; seul le **type** est en anglais, car il est normatif.

**Irreversibilite** — Nulle, mais un historique deja ecrit ne se reformate pas. D'ou
l'application des le premier commit.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| Aucune convention | Contraire au SDD §4.5. Rend la generation du changelog impossible. |
| Convention sans application automatique | Une convention non verifiee n'est pas appliquee au-dela du deuxieme sprint. |
| `semantic-release` (versionnage automatique) | Retire a l'equipe la maitrise du numero de version, alors que le SRS §14.8 impose des versions liees aux jalons (P1 = v0.1.0, P2 = v0.5.0, P3 = v1.0.0). |

## Mise en oeuvre

`commitlint.config.cjs`, `.husky/commit-msg`, `cliff.toml`,
job `titre-pr` de `.github/workflows/hygiene.yml`, `.github/workflows/release.yml`.
