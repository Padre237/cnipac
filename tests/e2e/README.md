# Tests de bout en bout

## Convention

Le nom de chaque test porte les identifiants des exigences qu'il couvre
(ADR-035). `scripts/gate-tracabilite.mjs` échoue si un identifiant est inconnu.

```ts
test('[AC-P1-03][FR-M2-01] la carte affiche 200 producteurs en clusters @e2e', async ({ page }) => { … });
test('[NFR-C7-01] la carte publique est accessible @a11y', async ({ page }) => { … });
test('[FR-M6-03] un rôle R-04 ne peut pas valider une soumission @rbac', async ({ page }) => { … });
```

## Étiquettes

| Étiquette | Exécution |
|---|---|
| `@e2e` | Suite complète, à chaque PR |
| `@a11y` | Porte d'accessibilité (ADR-030) |
| `@rbac` | Matrice des 8 rôles × points d'entrée sensibles (SDD §25.6) |
| `@smoke` | Tests de fumée post-déploiement |

## Les quatorze scénarios du SDD §25.4

1. Consultation publique anonyme de la carte — M2
2. Recherche par sigle et clic sur marqueur — M2
3. Connexion et accueil authentifié — M6
4. Validation d'une soumission en quarantaine — M1
5. Édition d'une fiche et génération de version — M4
6. Comparaison de deux versions — M4
7. Fusion contrôlée de deux fiches doublons — M4
8. Tableau de bord national et export PDF — M3
9. Création d'un compte et attribution de rôle — M6
10. Configuration MFA TOTP et connexion — M6
11. Proposition de mise à jour et validation — M5 + M4
12. Consultation de l'API publique avec clé — M7
13. Export EAC-CPF d'une notice d'autorité — M4 + M7
14. Consultation hors ligne après mise en cache — Front + M2

Les cinq parcours détaillés du SDD §25.9 (P-A à P-E) sont l'épine dorsale de
cette suite et s'exécutent **à chaque release, sans exception possible**.
