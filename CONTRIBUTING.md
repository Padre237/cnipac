# Contribuer à CNIPAC

## Avant tout

Le code de ce dépôt appartient à l'**État du Cameroun** (NFR-C9-04). Toute
contribution externe emporte cession des droits patrimoniaux, matérialisée par
la signature préalable de `docs/conventions/CESSION-DROITS.md`.

## Le cycle

1. Un ticket existe et est rattaché à une exigence du registre.
2. Branche `feat/CNIPAC-123-slug` depuis `main`, **72 h de durée de vie maximale**.
3. Développement, avec tests portant l'identifiant de l'exigence couverte.
4. `npm run lint && npm run typecheck && npm run test:unit && npm run gate:all` en local.
5. Pull request, modèle rempli, titre au format Conventional Commits.
6. **Deux approbations**, dont un CODEOWNER.
7. Fusion en squash.

Détail : [docs/conventions/GIT.md](docs/conventions/GIT.md) et
[DEVELOPPEMENT.md](docs/conventions/DEVELOPPEMENT.md).

## Quand faut-il écrire un ADR ?

Dès que le choix n'est dicté ni par le TDR, ni par le SRS, ni par le SDD, et
qu'il engage le projet au-delà de la pull request : une dépendance structurante,
un mécanisme de sécurité, une convention qui s'impose aux autres, un écart à un
document contractuel.

**Un choix non documenté est un défaut de livraison, au même titre qu'un test
rouge.** Modèle : [docs/adr/_TEMPLATE.md](docs/adr/_TEMPLATE.md).

## Ce qui bloquera votre pull request

| Contrôle                                                  | Motif                            |
| --------------------------------------------------------- | -------------------------------- |
| Lint ou typage                                            | NFR-C6-04 — zéro erreur tolérée  |
| Couverture sous le seuil du palier                        | NFR-C6-01, ADR-028               |
| Règle de gestion sans test dédié                          | ADR-035                          |
| Migration destructive sur une table protégée              | Art. 32 Loi 2024/001, ADR-027    |
| Migration non rétrocompatible                             | Prérequis du Blue-Green, ADR-032 |
| Budget de bundle dépassé                                  | NFR-C1-07, ADR-029               |
| Violation d'accessibilité `critical`/`serious`            | NFR-C7-01, ADR-030               |
| Licence hors allowlist                                    | NFR-C9-03, ADR-025               |
| Secret détecté, ou lu depuis une variable d'environnement | ADR-033                          |
| Donnée réelle dans un jeu de test                         | NFR-C4-01, ADR-034               |
| Rupture du contrat d'API sans versionnement               | FR-M7-08, ADR-037                |

Aucun de ces contrôles n'est arbitraire : chacun protège une exigence
contractuelle nommée. En cas de désaccord sur un contrôle, le débat porte sur
l'ADR, pas sur le contournement.

## Sécurité

Une vulnérabilité ne se signale pas par un ticket public. Voir
[SECURITY.md](SECURITY.md).
