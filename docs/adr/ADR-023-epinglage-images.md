# ADR-023 — Epingler toutes les images par digest et automatiser leur mise a jour

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI
- **Perimetre** : technique
- **Exigences concernees** : NFR-C5-05, NFR-C3-04, NFR-C6-06, SDD §8.1 (parite environnementale)

## Contexte

Le SDD §26.1 et §26.3 referencent les images par tag mobile : `postgis/postgis:16-3.4`,
`node:20-alpine`, `nginx:1.27-alpine`, `redis:7-alpine`. Un tag mobile pointe vers un
contenu qui change. La consequence pratique est qu'un `docker compose pull` de routine peut
faire passer la base de PostgreSQL 16.2 a 16.6, ou Nginx d'un correctif a un autre, **sans
qu'aucune trace n'en subsiste**.

Trois exigences y resistent mal : NFR-C5-05 (reconstruction integrale a l'identique),
la parite environnementale du SDD §8.1 (PREPROD et PROD doivent executer les memes
versions), et NFR-C3-04 (maitrise des vulnerabilites, qui suppose de savoir ce qui tourne).

## Decision

**1. Epinglage par digest** de toutes les images de base et de tous les services
d'infrastructure :

```yaml
image: postgis/postgis:16-3.4@sha256:<digest>
```

Le tag est conserve a cote du digest pour la lisibilite humaine ; le digest fait foi.

**2. Renovate** (licence AGPL-3.0, execute comme application GitHub, non distribue —
cf. ADR-025) ouvre une pull request a chaque nouveau digest. La mise a jour suit alors le
chemin normal : CI, scan Trivy, revue, fusion. Le changement devient une decision tracee.

**3. Regroupement et cadence** — configuration dans `renovate.json` :

| Categorie                               | Cadence                      | Fusion automatique                      |
| --------------------------------------- | ---------------------------- | --------------------------------------- |
| Correctifs de securite (alertes CVE)    | immediate                    | non                                     |
| Dependances npm, correctifs et mineures | hebdomadaire, regroupees     | oui si CI verte et couverture maintenue |
| Dependances npm, majeures               | a l'unite                    | non                                     |
| Images de base Docker                   | hebdomadaire                 | non                                     |
| Actions GitHub                          | mensuelle, epinglees par SHA | non                                     |

**4. Actions GitHub epinglees par SHA de commit** et non par tag : `actions/checkout@v4`
designe une reference mobile controlee par un tiers, qui s'execute avec les secrets du
workflow. Un tag deplace est un vecteur de compromission de chaine d'approvisionnement
documente.

**5. Gel avant jalon.** Renovate est suspendu pendant les 10 jours precedant chaque atelier
de restitution (A1, A2, A3). On ne change pas la chaine de construction a la veille d'une
demonstration officielle.

## Consequences

**Positives** — Ce qui tourne en PROD est identifiable au digest pres. La parite
PREPROD/PROD devient verifiable par comparaison de chaines. La reconstruction NFR-C5-05
produit un systeme identique, pas equivalent.

**Negatives / couts** — Flux de pull requests automatiques a traiter (estime : 3 a 6 par
semaine). La fusion automatique des correctifs mineurs, conditionnee a une CI verte, limite
la charge. Les digests rendent les fichiers Compose moins lisibles.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                              | Raison du rejet                                                                                                                    |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Tags mobiles conformes au SDD            | Rend NFR-C5-05 et la parite environnementale invérifiables.                                                                        |
| Epinglage par version exacte sans digest | Meilleur, mais les images officielles republient la meme version avec des correctifs de base. Seul le digest identifie le contenu. |
| Dependabot                               | Equivalent sur npm, nettement moins configurable sur le regroupement et la cadence.                                                |

## Mise en oeuvre

`renovate.json`, `infra/compose/*.yml`, `infra/docker/Dockerfile.*`,
job `coherence-versions` de `.github/workflows/ci.yml`.
