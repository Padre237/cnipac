# M2 — Visualisation cartographique

| | |
|---|---|
| **Exigences fonctionnelles** | FR-M2-01 a FR-M2-14 |
| **Regles de gestion** | RG-M2-01 a RG-M2-04 |
| **Conception** | SDD V4.0 |
| **Etat** | Palier 0 — squelette |

## Regle de developpement

Toute regle de gestion mise en oeuvre dans ce module doit avoir un test unitaire
dont le nom porte son identifiant. `scripts/gate-tracabilite.mjs` echoue sinon (ADR-035).

Les seuils de couverture de ce module sont definis par
[`docs/regles-metier/palier-courant.json`](../../../../../docs/regles-metier/palier-courant.json) (ADR-028).
