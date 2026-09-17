# Conventions de migration de schéma

**ADR** : [027](../adr/ADR-027-garde-fou-migrations.md), [032](../adr/ADR-032-blue-green-automatise.md)
**Exigences** : art. 32 Loi 2024/001, NFR-C2-01, RG-M1-04

## Les deux règles qui ne se négocient pas

### 1. Une migration appliquée est immuable

Prisma stocke le checksum de chaque migration appliquée. Modifier une migration
déjà déployée en PREPROD ou en PROD **empêche l'application de démarrer**. La
correction se fait par une **nouvelle** migration, jamais en éditant l'ancienne.
La CI le vérifie (`scripts/gate-migrations.mjs`).

### 2. Toute migration est rétrocompatible

Le déploiement Blue-Green fait cohabiter l'ancienne et la nouvelle version
applicative **sur la même base**, pendant la fenêtre de bascule. Une migration
qui casse l'ancienne version provoque des erreurs pendant tout le déploiement.

## Comment procéder en trois temps

Le schéma ci-dessous s'applique à tout changement destructif.

| Release | Base de données | Code applicatif |
|---|---|---|
| **N** | Ajouter la nouvelle colonne, **nullable** | Écrire dans les deux colonnes, lire l'ancienne |
| **N+1** | Remplir la nouvelle colonne (script de données) | Lire la nouvelle, écrire dans les deux |
| **N+2** | Supprimer l'ancienne colonne | Ne connaît plus que la nouvelle |

Trois releases pour renommer une colonne. C'est le prix d'un déploiement sans
interruption — et c'est moins cher qu'une indisponibilité en production.

## Ce qui est interdit, et pourquoi

| Opération | Motif |
|---|---|
| `DROP COLUMN` en une seule release | L'ancienne version applicative référence encore la colonne |
| `RENAME COLUMN` | Équivaut à un DROP + ADD pour l'ancienne version |
| `ALTER COLUMN … TYPE` | Réécriture de table sous verrou exclusif, et rupture de contrat |
| `SET NOT NULL` sans valeur par défaut | L'ancienne version insère des `NULL` |
| Toute opération destructive sur `evenement_audit` | **Article 32 de la Loi 2024/001** — la chaîne de hachage n'est pas reconstructible |
| Toute suppression dans `soumission_kobo` | **RG-M1-04** — la chaîne de preuve depuis la collecte terrain |
| Toute suppression dans `version_fiche` | UC-M4-07 et UC-M4-08 — historique et restauration de version |

## Verrous — la partie qu'on oublie

PostgreSQL prend un verrou exclusif sur plusieurs opérations courantes. Sur une
table de 15 000 lignes l'effet est imperceptible ; sur `evenement_audit` après
deux ans d'exploitation, il ne l'est plus.

```sql
-- Bloque les lectures ET les écritures pendant toute la construction.
CREATE INDEX idx_producteur_reseau ON producteur(reseau_id);

-- Ne bloque rien. Plus lent, mais sans interruption de service (NFR-C2-01).
CREATE INDEX CONCURRENTLY idx_producteur_reseau ON producteur(reseau_id);
```

`CREATE INDEX CONCURRENTLY` ne fonctionne pas dans une transaction : Prisma
exige alors une migration marquée en conséquence. La CI émet un avertissement
sur tout `CREATE INDEX` non concurrent : il faut soit corriger, soit justifier
dans la pull request.

## Exception justifiée

Une migration légitimement destructive — correction d'un défaut de conception
**avant toute mise en données réelles** — s'écrit ainsi :

```sql
-- CNIPAC-MIGRATION-EXCEPTION: correction du type de statut_conservation avant P1,
-- aucune donnée réelle en base. Ticket CNIPAC-142, validé par l'architecte.
ALTER TABLE producteur DROP COLUMN statut_conservation_ancien;
```

La CI accepte alors la migration, la journalise dans le résumé de job, et exige
l'approbation d'un CODEOWNER de `apps/backend/prisma/`. **Le contournement est
possible, jamais silencieux.**
