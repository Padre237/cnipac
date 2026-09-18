# ADR-027 — Instaurer un garde-fou CI sur les migrations de schema

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI
- **Perimetre** : technique et **metier**
- **Exigences concernees** : **art. 32 Loi 2024/001**, NFR-C3-05, RG-M1-04, RG-M4-yy, SDD ADR-009, SDD §12.12

## Contexte

Le SDD (ADR-009, §12.7, §23.7) definit le journal d'audit comme **append-only avec
hash-chaining** : chaque evenement contient le hachage du precedent, ce qui rend toute
modification ou suppression detectable. Cette propriete met en oeuvre l'article 32 de la Loi
2024/001 et l'exigence NFR-C3-05 (conservation 5 ans sans possibilite de purge anticipee).

Or **rien, dans aucun des trois documents, n'empeche techniquement un developpeur d'ecrire
une migration Prisma qui supprime ou modifie cette table.** Le risque n'est pas theorique :
une migration generee automatiquement apres un remaniement du schema Prisma peut produire
un `DROP COLUMN` sur `evenement_audit` sans intention malveillante. La chaine de hachage est
alors rompue, et la conformite legale du systeme avec elle — de maniere irreversible, la
table etant precisement concue pour ne pas etre reconstructible.

La meme logique s'applique a `soumission_kobo`, dont RG-M1-04 exige la conservation a vie
(« la reference a la soumission d'origine ne peut etre effacee meme en cas de modification
de la fiche »), et a `version_fiche`, qui porte l'historique exige par UC-M4-07 et UC-M4-08.

## Decision

Un controle bloquant `scripts/gate-migrations.mjs`, execute a **chaque pull request**.

**1. Tables protegees** — declarees dans `docs/regles-metier/tables-protegees.json` :

| Table             | Fondement                                    | Operations interdites                                                                     |
| ----------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `evenement_audit` | Art. 32 Loi 2024/001, NFR-C3-05, SDD ADR-009 | `DROP TABLE`, `DROP COLUMN`, `TRUNCATE`, `DELETE FROM`, `ALTER COLUMN ... TYPE`, `RENAME` |
| `soumission_kobo` | RG-M1-04                                     | `DROP TABLE`, `TRUNCATE`, `DELETE FROM`                                                   |
| `version_fiche`   | SDD ADR-006, UC-M4-07, UC-M4-08              | `DROP TABLE`, `TRUNCATE`, `DELETE FROM`                                                   |

L'ajout d'une colonne `NULL` reste autorise : il n'altere ni l'historique ni la chaine.

**2. Immuabilite des migrations appliquees.** Une migration deja appliquee en PREPROD ou en
PROD ne peut plus etre modifiee : Prisma en stocke le checksum et refuserait de demarrer.
Le controle compare les repertoires de `prisma/migrations/` a `prisma/migrations.lock`
(committe) et echoue si une migration existante a change de contenu. Une correction se fait
par une **nouvelle** migration, jamais par edition de l'ancienne.

**3. Operations verrouillantes signalees.** Tout `ALTER TABLE ... ADD COLUMN ... NOT NULL`
sans valeur par defaut, tout `CREATE INDEX` non `CONCURRENTLY` sur une table de plus de
10 000 lignes est signale comme **avertissement** : sur PostgreSQL, ces operations prennent
un verrou exclusif et provoquent une indisponibilite, en tension avec NFR-C2-01 (99,5 %).
L'avertissement exige une justification explicite dans le corps de la PR.

**4. Contournement trace.** Une migration legitimement destructive (correction d'un defaut
de conception avant toute mise en donnees reelles) passe par le marqueur
`-- CNIPAC-MIGRATION-EXCEPTION: <justification> / <ADR ou ticket>` dans le fichier SQL. Le
controle l'accepte alors, mais le journalise dans le resume de job et exige l'approbation
d'un CODEOWNER de `prisma/`. Le contournement est possible, jamais silencieux.

## Consequences

**Positives** — Une exigence legale devient une regle executable, verifiee a chaque PR
plutot qu'a l'audit annuel. C'est le seul dispositif du projet qui protege la conformite
article 32 contre l'erreur humaine ordinaire.

**Negatives / couts** — Faux positifs possibles sur des migrations legitimes ; traites par
le marqueur d'exception. Le controle analyse le SQL textuellement, sans comprendre la
semantique : il est volontairement conservateur.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                                       | Raison du rejet                                                                                                                                                        |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Revue humaine seule                               | Une revue humaine rate un `DROP COLUMN` noye dans une migration de 200 lignes. C'est exactement le mode de defaillance a couvrir.                                      |
| Droits PostgreSQL restreints sur la table d'audit | Complementaire et recommande en PROD, mais n'empeche pas la migration d'etre ecrite, fusionnee et de faire echouer le deploiement. Le defaut doit etre arrete a la PR. |
| Declencheur (trigger) `BEFORE DELETE` en base     | Egalement recommande en defense en profondeur, mais contournable par un `ALTER TABLE ... DISABLE TRIGGER` dans la meme migration.                                      |

## Mise en oeuvre

`scripts/gate-migrations.mjs`, `docs/regles-metier/tables-protegees.json`,
`apps/backend/prisma/migrations.lock`, job `garde-fou-migrations` de `.github/workflows/ci.yml`,
`.github/CODEOWNERS` (entree `apps/backend/prisma/`).
