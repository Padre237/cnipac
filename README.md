# CNIPAC — Carte Numérique Interactive des Producteurs d'Archives au Cameroun

[![CI](https://github.com/cenadi-cm/cnipac/actions/workflows/ci.yml/badge.svg)](https://github.com/cenadi-cm/cnipac/actions/workflows/ci.yml)
[![Sécurité](https://github.com/cenadi-cm/cnipac/actions/workflows/security.yml/badge.svg)](https://github.com/cenadi-cm/cnipac/actions/workflows/security.yml)

> Référentiel national des producteurs d'archives du secteur public camerounais.
> Mise en œuvre de l'**article 26 de la Loi n° 2024/001 du 24 juillet 2024** :
> le fichier unique et accessible des producteurs d'archives publiques.

**Maîtrise d'ouvrage** : CENADI (MINFI) — **Partenaire métier** : Archives
Nationales du Cameroun (MINAC) — **Phase pilote** : février à décembre 2026.

---

## État du dépôt

**Palier 0 — socle technique** (SDD §29.2, sprints S1 à S5).

Ce qui est livré à ce stade n'est pas une fonctionnalité : c'est **la capacité
de livrer**. Le pipeline, l'infrastructure, les portes de qualité, la
traçabilité des exigences et les conventions sont en place. Les sept modules
fonctionnels sont câblés et vides.

|                              |                                                                  |
| ---------------------------- | ---------------------------------------------------------------- |
| Exigences au registre        | **241** (82 FR, 47 NFR, 34 RG, 36 UC, 30 AC, 12 articles de loi) |
| Décisions d'architecture     | **26 ADR** (013 à 038), prolongeant les 012 du SDD               |
| Workflows CI/CD              | **12**                                                           |
| Portes de qualité bloquantes | **13**                                                           |
| Dérogations en vigueur       | **aucune** — conformité SRS V2.0 et SDD V4.0 à la lettre         |

## Démarrage

```bash
npm ci
cp .env.example .env
docker compose -f infra/compose/compose.ci.yml up -d postgres redis
npm run exec -w @cnipac/backend prisma migrate dev
npm run start:dev -w @cnipac/backend    # http://localhost:3000
npm run dev -w @cnipac/frontend         # http://localhost:5173
```

Guide complet : [docs/conventions/DEVELOPPEMENT.md](docs/conventions/DEVELOPPEMENT.md)

## Organisation

```
apps/backend          API NestJS — 7 modules fonctionnels (SRS chap. 5)
apps/frontend         PWA React — découpage par fonctionnalité (SDD §20.2)
packages/shared-types Énumérations et règles de gestion — SOURCE DE VÉRITÉ UNIQUE
infra/                Compose (3 piles), Dockerfiles, Nginx, PostgreSQL, supervision
docs/adr/             26 décisions d'architecture, argumentées
docs/runbooks/        Procédures d'exploitation
docs/traceability/    Registre des exigences + matrice générée
scripts/              Portes de qualité et outillage de déploiement
tests/                E2E Playwright, charge k6, sécurité ZAP
```

## Ce que le pipeline garantit

Chaque exigence chiffrée du SRS a un mécanisme qui l'applique. Ce n'est pas de
la documentation : ce sont des contrôles qui font échouer une pull request.

| Exigence                                            | Contrôle                       | Effet                         |
| --------------------------------------------------- | ------------------------------ | ----------------------------- |
| **Art. 32 Loi 2024/001** — journal d'audit immuable | `gate-migrations.mjs`          | Migration destructive refusée |
| **NFR-C1-07** — bundle ≤ 2 Mo gzip                  | `gate-bundle-budget.mjs`       | Budget 1,6 Mo, marge 20 %     |
| **NFR-C6-01** — couverture ≥ 70 %                   | Seuils Jest/Vitest             | M1/M4/M6 à 85–90 %            |
| **NFR-C7-01** — WCAG 2.1 AA                         | `vitest-axe`, Playwright       | Violation = fusion bloquée    |
| **NFR-C9-02** — pas de sortie de territoire         | `gate-affectation-runners.mjs` | Runner self-hosted imposé     |
| **NFR-C9-03/04** — souveraineté, propriété          | `gate-licences.mjs`, SBOM      | Copyleft fort refusé          |
| **NFR-C3-04** — 0 CVE HIGH/CRITICAL                 | `pnpm audit`, Trivy, ZAP       | Build rouge                   |
| **NFR-C3-07** — en-têtes durcis                     | `gate-entetes-securite.mjs`    | < 60 s, en PR                 |
| **NFR-C2-04** — RPO ≤ 1 h                           | Archivage WAL + exercice hebdo | RPO réel ~5 min               |
| **FR-M7-08** — API versionnée                       | `gate-api-contrat.mjs`         | Rupture sans version = refus  |
| **SRS chap. 15** — traçabilité                      | `gate-tracabilite.mjs`         | Matrice dérivée du code       |

## Déploiement

Trois environnements, isolation stricte (SDD §8.1). **Aucune donnée réelle hors
production** (ADR-034).

|          | Déclencheur         | Approbation        | Stratégie                       |
| -------- | ------------------- | ------------------ | ------------------------------- |
| DEV      | push sur `main`     | —                  | remplacement direct             |
| PREPROD  | CI verte sur `main` | —                  | Blue-Green automatique          |
| **PROD** | tag `vX.Y.Z` signé  | **2 approbateurs** | Blue-Green + observation 10 min |

La **décision** de déployer reste humaine ; l'**exécution** des huit étapes du
SDD §26.5 est automatisée, toujours à l'identique. Runbook :
[RB-02](docs/runbooks/RB-02-deploiement-production.md).

## Point d'attention pour le COPIL

Le dépôt applique le SRS et le SDD à la lettre ; aucune dérogation n'est en
vigueur. **Une contradiction interne aux documents contractuels** reste toutefois
à arbitrer : NFR-C2-04 exige un RPO ≤ 1 h, tandis que le SDD §4.4 et §27.4
décrivent une sauvegarde quotidienne, soit un RPO de 24 h. Le dépôt met en œuvre
le SDD ; l'exigence NFR-C2-04 n'est donc pas satisfaite en l'état. Voir
[docs/DEROGATIONS.md](docs/DEROGATIONS.md), point R-01.

## Pile technique

Node.js 22 LTS · TypeScript 5 · NestJS 10 · Prisma 5 · PostgreSQL 16 + PostGIS
3.4 · Redis 7 · React 18 · Vite 5 · Tailwind · Leaflet · TanStack Query ·
Zustand · Docker Compose · Nginx · Prometheus, Grafana, Loki

Pile intégralement conforme au SDD chapitre 4.

100 % open source, hébergeable sur infrastructure souveraine (NFR-C9-03).

## Documents de référence

| Document                                       | Emplacement                                |
| ---------------------------------------------- | ------------------------------------------ |
| TDR — Termes de référence                      | [docs/reference/](docs/reference/)         |
| Livrable 1.2 — Cahier d'analyse (SRS V2.0)     | [docs/reference/](docs/reference/)         |
| Livrable 1.3 — Cahier de conception (SDD V4.0) | [docs/reference/](docs/reference/)         |
| Maquettes Stitch                               | [docs/design/stitch/](docs/design/stitch/) |
| Registre des décisions                         | [docs/adr/README.md](docs/adr/README.md)   |
| Dérogations COPIL                              | [docs/DEROGATIONS.md](docs/DEROGATIONS.md) |

## Licence

Propriété de l'**État du Cameroun**, CENADI mandataire (NFR-C9-04).
Voir [LICENSE](LICENSE).
