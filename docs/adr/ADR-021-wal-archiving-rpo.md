# ADR-021 — Sauvegarde quotidienne pg_dump + age + rsync, conformement au SDD §4.4 et §27.4

- **Statut** : **REVISE — derogation retiree**, le SDD fait foi
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + RSSI
- **Perimetre** : technique et metier
- **Exigences concernees** : **NFR-C2-04**, NFR-C2-03, NFR-C2-05, NFR-C3-05, AC-P3-08, art. 32 Loi 2024/001

> **Cet ADR est ANNULE en tant que decision technique.** L'archivage WAL continu
> est **retire** sur instruction du maitre d'ouvrage.
>
> **Dispositif retenu : celui du SDD §4.4 et §27.4** — `pg_dump` quotidien,
> chiffrement `age`, transfert `rsync` vers le site de reprise, retention
> 30 jours en local et 12 mois en externalise (NFR-C2-05), restauration testee
> trimestriellement — l'exercice etant ici automatise et execute chaque semaine.
>
> **Le constat factuel qui a motive cet ADR n'est toutefois pas resolu par son
> annulation, et doit etre porte au COPIL :**
>
> - **NFR-C2-04** (SRS §10.3) exige un **RPO <= 1 heure** ;
> - le dispositif du SDD §27.4 est **quotidien**, soit un RPO de **24 heures**.
>
> Ces deux enonces sont contradictoires **a l'interieur meme des documents
> contractuels**. Respecter le SDD a la lettre implique donc de ne pas satisfaire
> NFR-C2-04. Il ne s'agit pas d'un choix d'implementation mais d'une incoherence
> documentaire, dont l'arbitrage appartient au Comite de Pilotage :
>
> **soit** NFR-C2-04 est amende pour inscrire un RPO de 24 heures,
> **soit** le SDD §27.4 est complete pour tenir le RPO de l'exigence.
>
> En l'etat, le depot met en oeuvre le SDD. Aucun code d'archivage WAL ne
> subsiste. Voir [../DEROGATIONS.md](../DEROGATIONS.md), point R-01.

---

_Le texte qui suit est conserve a titre de trace de l'analyse initiale._

## Contexte

Il existe une **incoherence quantifiee** entre deux exigences du dossier :

- **NFR-C2-04** (SRS §10.3) : « perte de donnees maximale de 1 heure en cas d'incident
  majeur (RPO) », cible mesurable **RPO <= 1 h**.
- **SDD §4.4 et §27.4**, et **NFR-C2-05** : sauvegardes par `pg_dump`, chiffrement `age`,
  transfert `rsync`, **frequence quotidienne**.

Une sauvegarde quotidienne donne mecaniquement un RPO de **24 heures**. L'ecart avec
l'exigence est d'un **facteur 24**. Ce n'est pas une approximation : c'est une exigence
contractuelle chiffree qui ne peut pas etre satisfaite par le dispositif decrit.

Consequence concrete : une defaillance de stockage a 18 h, avec un dump datant de 3 h,
detruit une journee entiere de validations d'archivistes (UC-M4-02) — et le **journal
d'audit correspondant**, dont l'article 32 de la Loi 2024/001 impose le caractere immuable
et dont NFR-C3-05 exige la conservation pendant 5 ans. La perte n'est alors pas seulement
operationnelle : elle est juridique.

## Decision

Dispositif de sauvegarde a **deux etages**, gere par **pgBackRest** (licence MIT) execute
en conteneur dedie dans la pile `compose.data.yml`.

| Etage | Mecanisme                      | Frequence                        | Retention         | RPO atteint      |
| ----- | ------------------------------ | -------------------------------- | ----------------- | ---------------- |
| 1     | Sauvegarde complete pgBackRest | hebdomadaire, dimanche 02h00     | 12 mois (site DR) | —                |
| 1 bis | Sauvegarde differentielle      | quotidienne, 02h00               | 30 jours (local)  | —                |
| 2     | **Archivage WAL continu**      | continu, `archive_timeout = 300` | 30 jours          | **<= 5 minutes** |

Parametres PostgreSQL : `wal_level = replica`, `archive_mode = on`,
`archive_command` delegue a pgBackRest, `archive_timeout = 300`.

Le `pg_dump` logique quotidien decrit au SDD **est conserve** en complement : il offre une
restauration selective table par table et une portabilite entre versions majeures que la
sauvegarde physique n'apporte pas. Les deux dispositifs sont complementaires, non
concurrents.

**Chiffrement** : `age` conforme au SDD §4.4, ou chiffrement natif pgBackRest (AES-256-CBC),
satisfaisant NFR-C3-02. Les cles sont gerees selon ADR-033 et **ne sont jamais stockees sur
l'hote sauvegarde**.

**Verification** : la restauration est testee automatiquement chaque semaine (ADR-027,
workflow `backup-restore-drill.yml`). Une sauvegarde non restauree n'est pas une sauvegarde.

## Consequences

**Positives** — Le RPO passe de 24 heures a environ 5 minutes ; NFR-C2-04 devient tenable.
La restauration a un instant precis (PITR) permet de revenir juste avant une operation
erronee, ce qu'un dump quotidien ne permet pas. Preuve documentaire pour AC-P3-08.

**Negatives / couts** — Un conteneur et une configuration supplementaires. Volumetrie
d'archives WAL estimee a 2 a 5 Go par mois a la volumetrie cible — negligeable devant les
2 To prevus pour le site DR (SDD §8.3). Charge d'exploitation : pgBackRest doit lui-meme
etre supervise, faute de quoi un archivage bloque sature le disque de la base. Une alerte
Prometheus dediee (`CnipacWalArchivageEnRetard`) est prevue a cet effet.

**Irreversibilite** — Faible, mais la mise en place doit avoir lieu **avant** la premiere
mise en donnees reelles. Apres, elle impose une fenetre d'arret.

## Alternatives ecartees

| Alternative                                      | Raison du rejet                                                                                                                                                                    |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pg_dump` quotidien seul, conforme au SDD        | Ne satisfait pas NFR-C2-04 : facteur 24 d'ecart.                                                                                                                                   |
| `pg_dump` horaire                                | Charge I/O horaire sur la base de production et fenetre de verrouillage repetee. Ne fournit pas de PITR.                                                                           |
| Replication en flux vers une instance secondaire | Repond a NFR-C2-06 (tolerance N-1) mais **pas** au besoin de sauvegarde : une suppression erronee se replique instantanement. Complementaire, a envisager en P3, pas substituable. |
| Snapshots du systeme de fichiers                 | Non transactionnels sur une base active. Risque de sauvegarde incoherente.                                                                                                         |

## Mise en oeuvre

`infra/compose/compose.data.yml` (service `pgbackrest`), `infra/backup/pgbackrest.conf`,
`infra/postgres/conf/postgresql.conf`, `.github/workflows/backup-restore-drill.yml`,
`infra/monitoring/prometheus/rules/sauvegardes.yml`,
`docs/runbooks/RB-04-restauration.md`.
