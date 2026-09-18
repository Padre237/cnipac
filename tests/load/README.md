# Tests de charge k6

**Exigences** : NFR-C1-01 à NFR-C1-07, NFR-C6-06 · **SDD** : §25.5 et §25.10

Exécutés en PREPROD sur le jeu de 15 000 producteurs synthétiques (ADR-034),
hors heures ouvrées de Yaoundé.

| Fichier                  | Scénario                                     | Cible                    |
| ------------------------ | -------------------------------------------- | ------------------------ |
| `01-carte-initiale.js`   | Chargement initial, 100 utilisateurs, 10 min | P95 ≤ 5 s (NFR-C1-01)    |
| `02-fiche-producteur.js` | Fiche synthétique, 200 utilisateurs, 5 min   | P95 ≤ 2 s                |
| `03-tableau-de-bord.js`  | Tableau national, 50 utilisateurs, 5 min     | P95 ≤ 800 ms (NFR-C1-02) |
| `04-ingestion-kobo.js`   | 500 soumissions en lot                       | < 10 min (FR-M1-01)      |
| `05-authentification.js` | 300 connexions/min, 5 min                    | P95 ≤ 1 s                |
| `06-api-publique.js`     | 60 req/s, 10 min                             | P95 ≤ 1 s, erreurs < 1 % |
| `07-export-csv.js`       | Export de 10 000 producteurs                 | ≤ 30 s (NFR-C1-05)       |

## Trajectoire par palier

P1 : 50 utilisateurs (optionnel) · **P2 : 200** (AC-P2-09) · **P3 : 500** (AC-P3-06)

## Profil réseau

Le SRS §2.4.2 impose une connexion 3G de référence : **1 Mbit/s, 100 ms de
latence**. C'est ce profil qui donne son sens à NFR-C1-01 — et au budget de
bundle d'ADR-029. Tester en gigabit ne prouve rien sur le terrain camerounais.
