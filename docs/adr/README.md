# Registre des Decisions d'Architecture (ADR) — CNIPAC

## Portee

Le Cahier de Conception V4.0 (SDD, chapitre 9) consigne les ADR **001 a 012**, qui portent
sur la conception applicative (ORM, RBAC, cache, JWT, versionnage, E2E, monolithe modulaire,
audit, secrets, i18n, PWA).

Le present registre **prolonge** cette numerotation a partir de **ADR-013**. Il couvre le
perimetre laisse ouvert par les documents de reference : l'ingenierie logicielle, la chaine
de construction, l'integration continue, le deploiement, l'exploitation des donnees et
l'outillage de conformite.

**Regle absolue du projet : aucun choix technique ou metier n'est implicite.** Tout choix
qui n'est pas dicte mot pour mot par le TDR, le SRS V2.0 ou le SDD V4.0 fait l'objet d'un
ADR. Un choix non documente est un defaut de livraison au meme titre qu'un test rouge.

## Statuts

| Statut      | Signification                                                                                                                 |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `ACCEPTE`   | Decision en vigueur, appliquee dans le depot.                                                                                 |
| `PROPOSE`   | Soumis a validation du COPIL ou de l'architecte CENADI.                                                                       |
| `SUPERSEDE` | Remplace par un ADR ulterieur (lien indique).                                                                                 |
| `REVISE`    | Derogation initialement envisagee, **retiree** : le SRS et le SDD font foi. Le texte est conserve a titre de trace d'analyse. |

## Index

### Organisation du code et de la forge

| ADR                                    | Titre                                                    | Statut  |
| -------------------------------------- | -------------------------------------------------------- | ------- |
| [013](ADR-013-monorepo.md)             | Monorepo pnpm workspaces plutot que depots separes       | ACCEPTE |
| [014](ADR-014-forge-et-runners.md)     | GitHub prive institutionnel + runners self-hosted CENADI | ACCEPTE |
| [015](ADR-015-registry.md)             | Registry GHCR transitoire, cible Harbor CENADI           | ACCEPTE |
| [016](ADR-016-modele-de-branches.md)   | Trunk-based, branches courtes, releases par tag          | ACCEPTE |
| [017](ADR-017-node-24-lts.md)          | Node.js 22 LTS (dans l'enveloppe SDD §4.2)               | ACCEPTE |
| [018](ADR-018-pnpm.md)                 | npm, conformement au SDD §26.4                           | REVISE  |
| [019](ADR-019-pas-de-turborepo.md)     | Aucun orchestrateur de monorepo en P1                    | ACCEPTE |
| [036](ADR-036-conventional-commits.md) | Conventional Commits et changelog genere                 | ACCEPTE |

### Donnees et persistance

| ADR                                    | Titre                                                         | Statut  |
| -------------------------------------- | ------------------------------------------------------------- | ------- |
| [020](ADR-020-tier-donnees-separe.md)  | Compose unique et volumes nommes (SDD §26.3)                  | REVISE  |
| [021](ADR-021-wal-archiving-rpo.md)    | Sauvegarde quotidienne pg_dump + age (SDD §27.4)              | REVISE  |
| [022](ADR-022-redis-persistance.md)    | Persistance Redis AOF obligatoire (revocation JWT)            | ACCEPTE |
| [027](ADR-027-garde-fou-migrations.md) | Garde-fou CI sur les migrations Prisma (audit append-only)    | ACCEPTE |
| [034](ADR-034-donnees-de-test.md)      | Interdiction des donnees reelles hors PROD, jeux synthetiques | ACCEPTE |

### Chaine de construction et qualite

| ADR                                       | Titre                                             | Statut  |
| ----------------------------------------- | ------------------------------------------------- | ------- |
| [023](ADR-023-epinglage-images.md)        | Epinglage des images par digest, Renovate         | ACCEPTE |
| [024](ADR-024-sbom-signature.md)          | SBOM CycloneDX et signature cosign par cle        | ACCEPTE |
| [025](ADR-025-licences.md)                | Allowlist de licences et perimetre d'application  | ACCEPTE |
| [026](ADR-026-couverture-locale.md)       | Codecov, conformement au SDD §26.4                | REVISE  |
| [028](ADR-028-seuils-couverture.md)       | Seuils de couverture differencies et progressifs  | ACCEPTE |
| [029](ADR-029-budget-bundle.md)           | Budget de bundle applique en CI                   | ACCEPTE |
| [030](ADR-030-accessibilite-bloquante.md) | Accessibilite bloquante a la PR                   | ACCEPTE |
| [031](ADR-031-dast-zap.md)                | DAST OWASP ZAP hors chemin critique de PR         | ACCEPTE |
| [035](ADR-035-tracabilite-outillee.md)    | Matrice de tracabilite outillee et verifiee en CI | ACCEPTE |

### Deploiement et exploitation

| ADR                                     | Titre                                                | Statut  |
| --------------------------------------- | ---------------------------------------------------- | ------- |
| [032](ADR-032-blue-green-automatise.md) | Blue-Green automatise avec approbation manuelle PROD | ACCEPTE |
| [033](ADR-033-gestion-secrets.md)       | Docker secrets + GitHub Environments, rotation       | ACCEPTE |
| [037](ADR-037-versionnage-api-pwa.md)   | Versionnage de l'API et invalidation du cache PWA    | ACCEPTE |
| [038](ADR-038-observabilite-slo.md)     | SLO encodes en regles Prometheus                     | ACCEPTE |

## Conformite aux documents contractuels

**Aucune derogation n'est en vigueur.** Le depot met en oeuvre le SRS V2.0 et le
SDD V4.0 a la lettre. Cinq ADR (017, 018, 020, 021, 026) portaient initialement
des propositions d'ecart : elles ont ete **retirees** et les ADR sont marques
`REVISE`, le texte etant conserve a titre de trace d'analyse.

Un point reste a arbitrer par le COPIL — il ne s'agit pas d'une derogation mais
d'une **contradiction interne aux documents contractuels** entre NFR-C2-04
(RPO <= 1 h) et le SDD §27.4 (sauvegarde quotidienne). Voir
[../DEROGATIONS.md](../DEROGATIONS.md), point R-01.

## Modele

Tout nouvel ADR suit [_TEMPLATE.md](_TEMPLATE.md).
