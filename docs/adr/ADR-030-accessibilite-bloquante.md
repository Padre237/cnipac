# ADR-030 — Rendre l'accessibilite bloquante a la pull request

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : tech lead + referent accessibilite ANC
- **Perimetre** : technique et **metier**
- **Exigences concernees** : **NFR-C7-01 a NFR-C7-04**, AC-P2-10, AC-P3 (95 %), SDD §22.2, §25.7

## Contexte

Le SRS exige la conformite **WCAG 2.1 niveau AA** (NFR-C7-01), la navigation au clavier
integrale (NFR-C7-02), des contrastes de 4,5:1 et 3:1 (NFR-C7-03) et un fonctionnement des
360x640 (NFR-C7-04). Les criteres d'acceptation fixent 90 % en P2 et 95 % en P3.

Le SDD §25.7 pose la regle : « tout composant introduisant une violation WCAG 2.1 AA
**bloque la fusion** ». C'est la bonne regle, et elle n'est outillee nulle part.

L'enjeu depasse la conformite formelle. Le systeme est destine a des utilisateurs de
l'administration camerounaise, sur des terminaux modestes, parfois avec des lecteurs
d'ecran. L'accessibilite corrigee apres coup coute cinq a dix fois le prix de
l'accessibilite construite.

## Decision

Trois niveaux de controle, deux bloquants.

**Niveau 1 — composant, bloquant.** `vitest-axe` sur chaque composant non trivial. Toute
violation de niveau `critical` ou `serious` fait echouer le test. Regle de revue : un
nouveau composant sans test d'accessibilite n'est pas approuve.

**Niveau 2 — page, bloquant.** `@axe-core/playwright` sur les huit ecrans structurants,
dans la suite E2E marquee `@a11y` :

| Ecran                        | Reference maquette |
| ---------------------------- | ------------------ |
| Carte publique               | IHM-PUB-01         |
| Fiche synthetique producteur | IHM-PUB-02         |
| Recherche                    | IHM-PUB-03         |
| Connexion                    | IHM-AUTH-01        |
| Saisie TOTP                  | IHM-AUTH-02        |
| Console de quarantaine       | IHM-ADM-01         |
| Detail fiche quarantaine     | IHM-ADM-02         |
| Tableau de bord national     | M3                 |

Verifications complementaires **non couvrables par axe-core**, scriptees explicitement :
parcours complet au clavier de chaque ecran sans piege de focus (NFR-C7-02), ordre de
tabulation coherent, visibilite du focus, et **accessibilite clavier de la carte Leaflet** —
point notoirement defaillant des cartographies web, et explicitement exige par NFR-C7-02
(« navigation, formulaires, **carte** »).

**Niveau 3 — audit, non bloquant.** Lighthouse Accessibility sur PREPROD, hebdomadaire, avec
suivi du score. Complete par l'audit manuel trimestriel (NVDA, VoiceOver) et l'audit externe
annuel prevus au SDD §25.7.

**Contrastes** : verifies statiquement sur les jetons de design (`packages/shared-types` ou
la configuration Tailwind) par `scripts/gate-contrastes.mjs`. Une couleur du design system
qui ne respecte pas 4,5:1 sur son fond d'usage est rejetee **avant** d'etre utilisee dans un
composant. Le design system `sovereign_heritage_design_system` presente dans
`docs/design/stitch/` est la source de ces jetons.

**Regime transitoire** : au Palier 0 et jusqu'au Sprint 8, le niveau 2 est en avertissement,
le temps que les ecrans existent. Le niveau 1 est bloquant des le premier composant.

## Consequences

**Positives** — L'accessibilite est construite, pas rattrapee. Les cibles AC-P2-10 (90 %) et
P3 (95 %) deviennent atteignables sans chantier de reprise. Le controle des contrastes en
amont evite la reprise de maquettes deja implementees.

**Negatives / couts** — Un test supplementaire par composant (environ 10 lignes). axe-core
ne detecte automatiquement qu'environ 57 % des criteres WCAG : l'audit manuel reste
indispensable et ne doit pas etre considere comme redondant.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                            | Raison du rejet                                                                                                     |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Audit d'accessibilite en fin de projet | Mode de defaillance classique : les defauts sont structurels et leur correction impose de reprendre les composants. |
| Lighthouse seul                        | Audit par page, sans granularite composant. Ne detecte pas les pieges de focus ni l'ordre de tabulation.            |
| Non bloquant, simple signalement       | Un avertissement non bloquant est ignore. Le SDD §25.7 prescrit explicitement le blocage.                           |

## Mise en oeuvre

`apps/frontend/vitest.config.ts` (`vitest-axe`), `tests/e2e/a11y/`,
`scripts/gate-contrastes.mjs`, job `accessibilite` de `.github/workflows/quality-gates.yml`,
`docs/conventions/ACCESSIBILITE.md`.
