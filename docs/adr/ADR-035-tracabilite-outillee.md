# ADR-035 — Outiller la matrice de tracabilite et la verifier en continu

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + chef de projet
- **Perimetre** : technique et **metier**
- **Exigences concernees** : SRS chapitre 15, SDD chapitre 30, **art. 26 et 32 Loi 2024/001**, NFR-C6-05

## Contexte

Le SRS chapitre 15 et le SDD chapitre 30 consacrent chacun un chapitre entier a la matrice
de tracabilite reliant besoins metier, cas d'utilisation, exigences fonctionnelles, regles de
gestion, tests d'acceptation et articles de loi. Le SRS enonce l'objectif : « toute exigence
est testable », « aucun element ne doit demeurer orphelin ».

Cette matrice existe aujourd'hui sous forme de **tableaux dans deux documents Word**. Elle
sera obsolete au troisieme sprint. C'est le sort de toute matrice de tracabilite maintenue a
la main — et c'est d'autant plus dommageable ici que le SRS en fait « l'instrument de defense
du projet en cas de contestation » devant une autorite de controle.

## Decision

La tracabilite devient une donnee du depot, verifiee mecaniquement.

**1. Registre unique.** `docs/traceability/exigences.json` contient l'integralite des
identifiants : 18+ FR par module, NFR-C1 a C9, RG-M1 a RG-TR, UC, AC-P1/P2/P3, et les
articles de la Loi 2024/001. Chaque entree porte : identifiant, libelle, source documentaire
et page, module, palier de livraison, criticite, mode de verification.

**2. Marquage dans les tests.** Chaque test porte les identifiants qu'il couvre, dans son
nom ou une etiquette :

```ts
it('[RG-M1-02] le code unique genere n est jamais modifiable', ...)
test('[AC-P1-03][FR-M2-01] la carte affiche 200 producteurs en clusters @e2e', ...)
```

**3. Controle bloquant** `scripts/gate-tracabilite.mjs`, a chaque PR :

| Verification                                              | Effet                                                                |
| --------------------------------------------------------- | -------------------------------------------------------------------- |
| Un test reference un identifiant **inconnu** du registre  | **Echec** — faute de frappe ou exigence non declaree                 |
| Une exigence du **palier courant** n'a aucun test         | **Echec** apres le sprint de cloture du palier ; avertissement avant |
| Une exigence d'un palier **futur** n'a aucun test         | Information seulement                                                |
| Une regle de gestion **RG-Mx-yy** n'a aucun test unitaire | **Echec** — exigence renforcee d'ADR-028                             |
| Un article de loi couvert n'a aucune exigence rattachee   | **Echec** — c'est le lien de conformite legale                       |

**4. Matrice generee, jamais ecrite a la main.**
`docs/traceability/MATRICE.md` est reconstruite a chaque fusion sur `main` et committee
automatiquement. Le document Word cesse d'etre la source ; il en devient un export.

**5. Rapport de conformite par jalon.** Avant chaque atelier A1, A2, A3,
`scripts/rapport-conformite.mjs` produit un document de recette listant, exigence par
exigence, le ou les tests qui la couvrent et leur dernier resultat. C'est la piece a joindre
au proces-verbal de recette (SRS §14.6) et a l'audit de securite AC-P3-05.

## Consequences

**Positives** — La matrice reste vraie, parce qu'elle est derivee du code plutot que
maintenue en parallele. La question « FR-M4-07 est-elle testee ? » se repond en une commande.
La preuve de conformite legale devient un artefact reproductible, ce qui est exactement ce
que le SRS chapitre 15 attend d'elle.

**Negatives / couts** — Constitution initiale du registre : environ 2 jours de saisie depuis
les deux documents. Discipline de marquage a tenir, mais elle se limite a une convention de
nommage des tests. Le controle est volontairement progressif pour ne pas bloquer le Palier 0,
ou presque aucune exigence n'est encore couverte.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                                     | Raison du rejet                                                                                                         |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Matrice Word maintenue a la main                | Obsolete des le troisieme sprint. Sans valeur probatoire.                                                               |
| Outil de gestion des exigences (Jira, Polarion) | Ajoute un systeme externe a synchroniser. Contraire a la sobriete du SDD §4. Les identifiants vivent deja dans le code. |
| Aucune tracabilite outillee                     | Le SRS chapitre 15 et le SDD chapitre 30 en font une piece contractuelle.                                               |

## Mise en oeuvre

`docs/traceability/exigences.json`, `scripts/gate-tracabilite.mjs`,
`scripts/rapport-conformite.mjs`, `docs/traceability/MATRICE.md` (genere),
job `tracabilite` de `.github/workflows/ci.yml`,
`.github/workflows/traceability.yml` (regeneration sur `main`).
