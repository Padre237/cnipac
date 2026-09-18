# M4 — Gestion des producteurs et mises a jour

|                              |                      |
| ---------------------------- | -------------------- |
| **Exigences fonctionnelles** | FR-M4-01 a FR-M4-14  |
| **Regles de gestion**        | RG-M4-01 a RG-M4-05  |
| **Conception**               | SDD V4.0             |
| **Etat**                     | Palier 0 — squelette |

## Regle de developpement

Toute regle de gestion mise en oeuvre dans ce module doit avoir un test unitaire
dont le nom porte son identifiant. `scripts/gate-tracabilite.mjs` echoue sinon (ADR-035).

Les seuils de couverture de ce module sont definis par
[`docs/regles-metier/palier-courant.json`](../../../../../docs/regles-metier/palier-courant.json) (ADR-028).
