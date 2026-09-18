# Registre des règles métier

Les 34 règles de gestion du SRS chapitre 11 constituent l'**invariant
fonctionnel** du système : tout choix d'implémentation doit pouvoir leur être
confronté sans contradiction.

Ce document indique, pour chaque règle, **où elle est appliquée** et **où elle
est vérifiée**. La liste complète et à jour, avec l'état de couverture réel, est
dans [la matrice de traçabilité](../traceability/MATRICE.md), générée
automatiquement.

## Trois niveaux d'application

| Niveau              | Mécanisme                                                                           | Exemples                                                             |
| ------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Code partagé**    | `packages/shared-types/src/regles-metier.ts` — fonctions pures, 100 % de couverture | RG-M1-02, RG-M1-03, RG-M1-05, RG-M2-01, RG-M2-03, RG-M3-01, RG-M3-02 |
| **Base de données** | Contraintes, types ENUM, tables protégées                                           | RG-M1-04, RG-TR-02                                                   |
| **Pipeline**        | Portes de qualité bloquantes                                                        | art. 32 via ADR-027, NFR-C4-04 via ADR-038                           |

## Les règles que le pipeline protège directement

C'est la partie qui distingue ce dépôt d'un dépôt ordinaire : certaines règles
métier ne sont pas seulement implémentées, elles sont **rendues impossibles à
violer par inadvertance**.

| Règle ou article                                    | Protection                     | Mécanisme                                                      |
| --------------------------------------------------- | ------------------------------ | -------------------------------------------------------------- |
| **Art. 32 Loi 2024/001** — journal d'audit immuable | `gate-migrations.mjs`          | Toute migration destructive sur `evenement_audit` échoue en PR |
| **RG-M1-04** — référence Kobo conservée à vie       | `gate-migrations.mjs`          | Idem sur `soumission_kobo`                                     |
| **UC-M4-07/08** — historique des versions           | `gate-migrations.mjs`          | Idem sur `version_fiche`                                       |
| **NFR-C4-01** — données nominatives non exposées    | `gate-donnees-test.mjs`        | Aucune donnée réelle dans les jeux versionnés                  |
| **NFR-C9-04** — propriété du code par l'État        | `gate-licences.mjs`            | Aucune dépendance copyleft fort liée au code livré             |
| **NFR-C9-02** — pas de sortie de territoire         | `gate-affectation-runners.mjs` | Aucun job manipulant des données réelles sur un runner hébergé |
| **FR-M7-04/08** — URI pérennes, API versionnée      | `gate-api-contrat.mjs`         | Aucune rupture de contrat sans changement de version           |
| **NFR-C1-07** — poids sur connexion 3G              | `gate-bundle-budget.mjs`       | Budget dépassé = fusion refusée                                |
| **NFR-C7-01** — WCAG 2.1 AA                         | `vitest-axe` + Playwright      | Violation `critical`/`serious` = test rouge                    |
| **NFR-C6-01** — couverture de tests                 | seuils Jest/Vitest             | Seuil non atteint = build rouge                                |

## Modifier une règle

Une règle de gestion vient du SRS, lui-même validé par le COPIL. Elle ne se
modifie pas par une pull request ordinaire.

1. Demande d'évolution avec justification métier, portée par les ANC ;
2. Arbitrage du COPIL, consigné ;
3. Mise à jour du SRS **et** de `docs/traceability/exigences.json` ;
4. Mise à jour du code et des tests portant l'identifiant ;
5. Approbation d'un CODEOWNER métier ANC **et** d'un architecte
   (`.github/CODEOWNERS` couvre `docs/regles-metier/` et `packages/shared-types/`).

Le cas particulier de **RG-M3-01** (indice de maturité archivistique) est
explicite dans le SRS : « toute évolution de cette formule fait l'objet d'une
note officielle ANC ». La pondération vit dans `PONDERATION_MATURITE`, et un
test vérifie que la somme vaut exactement 1 — une dérive fausserait tous les
indicateurs nationaux.
