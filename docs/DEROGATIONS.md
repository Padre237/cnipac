# Conformité au SRS V2.0 et au SDD V4.0 — état des écarts

**Destinataire** : Comité de Pilotage du projet CNIPAC
**Émetteur** : Équipe technique CENADI
**Date** : 17 septembre 2026

---

## Position retenue

**Aucune dérogation n'est demandée.** Sur instruction du maître d'ouvrage, le
dépôt met en œuvre le Cahier d'Analyse V2.0 et le Cahier de Conception V4.0
**à la lettre**. Les cinq dérogations envisagées en phase de préparation ont été
**retirées** ; les ADR correspondants sont marqués comme révisés et conservent
la trace de l'analyse.

| Réf      | Objet                     | Décision                                                                                   |
| -------- | ------------------------- | ------------------------------------------------------------------------------------------ |
| ~~D-01~~ | Node.js 24                | **Retirée.** Node **22 LTS**, expressément prévu par le SDD §4.2                           |
| ~~D-02~~ | pnpm                      | **Retirée.** `npm ci` et workspaces npm, conformément au SDD §26.4                         |
| ~~D-03~~ | Abandon de Codecov        | **Retirée.** `codecov/codecov-action@v4`, conformément au SDD §26.4                        |
| ~~D-04~~ | Isolation du tier données | **Retirée.** `docker-compose.yml` + 3 overrides, volumes nommés, conformément au SDD §26.3 |
| ~~D-05~~ | Archivage WAL continu     | **Retirée.** `pg_dump` + `age` + `rsync` quotidien, conformément au SDD §4.4 et §27.4      |

---

## Un point qui reste à arbitrer, et qui n'est pas un choix technique

### R-01 — Contradiction interne entre NFR-C2-04 et le SDD §27.4

Ce point n'est pas une demande de dérogation. C'est une **incohérence entre deux
passages des documents contractuels**, qui ne peut pas être levée par
l'implémentation.

| Source                   | Énoncé                                                                                                                                     |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **SRS §10.3, NFR-C2-04** | « Le système DOIT garantir une perte de données maximale de **1 heure** en cas d'incident majeur (RPO). » Cible mesurable : **RPO ≤ 1 h**. |
| **SDD §4.4 et §27.4**    | Sauvegardes par `pg_dump`, chiffrement `age`, transfert `rsync`, **fréquence quotidienne**.                                                |

Une sauvegarde quotidienne produit mécaniquement un RPO de **24 heures**.
L'écart avec l'exigence est d'un **facteur 24**.

**Conséquence de la position retenue** : le dépôt met en œuvre le SDD. Le RPO
effectif du système est donc de 24 heures, et **NFR-C2-04 n'est pas satisfaite**.
Une défaillance de stockage en fin de journée détruirait une journée entière de
validations d'archivistes, ainsi que le journal d'audit correspondant — dont
l'article 32 de la Loi 2024/001 impose l'immuabilité et NFR-C3-05 la
conservation pendant 5 ans.

**L'arbitrage appartient au COPIL.** Deux voies, l'une et l'autre recevables :

1. **Amender NFR-C2-04** pour y inscrire un RPO de 24 heures, cohérent avec le
   dispositif de sauvegarde retenu. Le SRS devient alors cohérent avec lui-même.
2. **Compléter le SDD §27.4** d'un mécanisme permettant de tenir le RPO de
   l'exigence. L'analyse technique correspondante est conservée dans
   [ADR-021](adr/ADR-021-wal-archiving-rpo.md), à titre documentaire.

**En l'absence de décision, la voie 1 s'applique de fait** : le système
fonctionnera avec un RPO de 24 heures. Il importe que ce soit constaté et
assumé explicitement, et non découvert lors d'un incident ou d'un audit.

**Échéance** : avant la mise en production. Au-delà, l'exigence figure au dossier
contractuel sans être tenue.

---

## Points signalés pour information, sans demande

Ces trois points n'appellent aucune décision. Ils sont consignés pour que
l'équipe et le COPIL en aient connaissance.

| Point                     | Constat                                                                                                                                                                                      |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Codecov**               | Service SaaS étranger recevant les chemins de fichiers et la structure interne du système. En tension avec NFR-C9-02 et NFR-C9-03. Retenu conformément au SDD §26.4.                         |
| **Volumes Docker nommés** | Sensibles à `docker compose down -v` et `docker system prune --volumes`. La protection est procédurale (runbook RB-05) et non technique. `scripts/deploy.sh` refuse néanmoins l'option `-v`. |
| **Dépendances fantômes**  | Les workspaces npm autorisent l'import d'un paquet non déclaré. Traité par la revue de code, non par l'outillage.                                                                            |

---

## Deux paramètres d'exécution non spécifiés par le SDD

Ils ne modifient aucune décision de conception : le SDD ne les aborde pas.

| Paramètre                                          | Motif                                                                                                                                                                  |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `shm_size: 1gb` sur PostgreSQL                     | Le défaut Docker (64 Mo) provoque des `could not resize shared memory segment` intermittents sur les vues matérialisées du module M3 (SDD §12.10).                     |
| Persistance Redis (`appendonly yes`, `noeviction`) | Redis porte la liste de révocation des JWT (SDD §4.2). Sans persistance, un redémarrage réactive les jetons révoqués, y compris ceux de comptes désactivés (UC-M6-02). |
