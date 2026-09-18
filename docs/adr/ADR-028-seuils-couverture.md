# ADR-028 — Appliquer des seuils de couverture differencies et progressifs

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : tech lead
- **Perimetre** : technique
- **Exigences concernees** : **NFR-C6-01**, SDD §25.8, SRS §14.7

## Contexte

Trois passages du dossier fixent des seuils de couverture, et ils ne disent pas la meme chose.

| Source                    | Seuil                                                           |
| ------------------------- | --------------------------------------------------------------- |
| NFR-C6-01 (SRS §10.7)     | >= 70 % « sur les modules metier »                              |
| SRS §14.7 (plan de tests) | P1 >= 50 %, P2 >= 65 %, P3 >= 70 %                              |
| SDD §25.8                 | Backend >= 70 %, **modules M1/M4/M6 >= 85 %**, frontend >= 60 % |

Il faut une regle unique, appliquee mecaniquement, qui satisfasse les trois. La lecture
retenue est la suivante : le SRS §14.7 decrit une **trajectoire dans le temps**, le SDD §25.8
decrit une **repartition par composant**. Les deux sont compatibles si l'on croise les axes.

Un seuil global unique serait par ailleurs trompeur : 70 % de couverture globale peut
parfaitement signifier 95 % sur du code trivial et 30 % sur le module d'audit.

## Decision

Matrice a deux dimensions, appliquee par `coverageThreshold` (Jest) et `thresholds`
(Vitest), par chemin.

| Perimetre                   | P1        | P2    | P3       | Fondement                                                                                    |
| --------------------------- | --------- | ----- | -------- | -------------------------------------------------------------------------------------------- |
| Backend global              | 50 %      | 65 %  | **70 %** | NFR-C6-01, SRS §14.7                                                                         |
| **M1** Ingestion            | 65 %      | 80 %  | **85 %** | SDD §25.8 — porte d'entree des donnees                                                       |
| **M4** Producteurs          | 65 %      | 80 %  | **85 %** | SDD §25.8 — cycle de vie et versionnage                                                      |
| **M6** Admin / RBAC / Audit | 70 %      | 85 %  | **90 %** | SDD §25.8, releve a 90 % : art. 32 Loi 2024/001                                              |
| M2, M3, M5, M7              | 50 %      | 65 %  | 70 %     | Regle generale                                                                               |
| `packages/shared-types`     | **100 %** | 100 % | 100 %    | Regles de gestion pures, sans dependance : aucune raison de ne pas les couvrir integralement |
| Frontend global             | 40 %      | 55 %  | **60 %** | SDD §25.8                                                                                    |
| Frontend `shared/`          | 60 %      | 70 %  | 75 %     | Code transverse, mutualise                                                                   |

**Releve a 90 % pour M6** : le module porte le RBAC, la revocation de jetons et le journal
d'audit a chaine de hachage. Un defaut non couvert y a des consequences juridiques, pas
seulement fonctionnelles.

**Deux exigences complementaires, plus importantes que le pourcentage lui-meme :**

1. **Toute regle de gestion RG-Mx-yy du SRS chapitre 11 possede au moins un test unitaire
   dedie**, portant l'identifiant de la regle dans son nom (`RG-M1-02 — le code unique n'est
jamais modifiable`). Verifie par ADR-035, non par le pourcentage.
2. **Aucune regression** : la couverture d'un module ne peut diminuer de plus de 0,5 point
   entre deux PR sans justification explicite (ADR-026).

Le palier courant est declare dans `docs/regles-metier/palier-courant.json` — un seul
fichier a modifier au passage de jalon.

## Consequences

**Positives** — Les seuils exigeants portent sur le code ou ils comptent. La trajectoire
progressive evite le cout mort d'un seuil a 85 % sur un module encore squelettique au
Sprint 6. Le lien regle de gestion / test rend la couverture qualitative, pas seulement
quantitative.

**Negatives / couts** — Configuration plus verbeuse. Le passage de palier est une operation
volontaire : s'il est oublie, le systeme reste au seuil precedent. Une alerte du workflow
`hygiene.yml` le rappelle a l'approche de chaque jalon.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                | Raison du rejet                                                                              |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| Seuil global unique a 70 % | Masque les disparites. Permet 30 % sur le module d'audit.                                    |
| 85 % partout des P1        | Produit des tests ecrits pour le compteur, pas pour la valeur. Contre-productif au Sprint 6. |
| Aucun seuil, revue humaine | NFR-C6-01 fixe une cible chiffree verifiable.                                                |

## Mise en oeuvre

`apps/backend/jest.config.ts`, `apps/frontend/vitest.config.ts`,
`docs/regles-metier/palier-courant.json`, `scripts/gate-coverage.mjs`.
