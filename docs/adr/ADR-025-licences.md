# ADR-025 — Definir une allowlist de licences et son perimetre d'application

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + direction juridique CENADI
- **Perimetre** : technique et **juridique**
- **Exigences concernees** : **NFR-C9-03**, **NFR-C9-04**, critere C-01 du SDD §4.1

## Contexte

NFR-C9-03 exige que « l'ensemble des technologies utilisees soit open source ou libre de
redevance ». NFR-C9-04 exige que le code source appartienne integralement a l'Etat du
Cameroun. Ces deux exigences peuvent entrer en conflit : une licence copyleft fort comme
l'AGPL-3.0, si elle contamine le code du projet, impose la publication du code derive — ce
qui peut contredire la maitrise souhaitee par l'Etat sur la diffusion de son systeme.

Or la stack retenue par le SDD §4 contient **precisement** de telles licences :

| Composant | Licence | Situation |
|---|---|---|
| PostGIS | GPL-2.0 | Processus separe, appele par le protocole PostgreSQL |
| k6 | AGPL-3.0 | Outil de test, jamais distribue avec le systeme |
| Grafana | AGPL-3.0 | Service separe, non modifie |
| Loki | AGPL-3.0 | Service separe, non modifie |
| axe-core | MPL-2.0 | Copyleft faible, par fichier |

Le SDD ne dit pas comment ces composants se concilient avec NFR-C9-04. **Le critere
juridique pertinent n'est pas la licence en elle-meme, mais le mode de liaison.**

## Decision

Trois perimetres, trois regimes.

**Perimetre A — dependances liees au code livre** (`dependencies` du backend et du frontend,
tout ce qui entre dans un artefact distribue). Allowlist stricte :

`MIT`, `Apache-2.0`, `BSD-2-Clause`, `BSD-3-Clause`, `ISC`, `0BSD`, `Unlicense`, `CC0-1.0`,
`PostgreSQL`, `Python-2.0`, `BlueOak-1.0.0`, `MPL-2.0` (copyleft par fichier, sans
contamination du projet tant que le fichier n'est pas modifie).

**Interdit sans derogation** : `GPL-*`, `AGPL-*`, `LGPL-*`, `SSPL-*`, `BUSL-*`, `Elastic-2.0`,
`CC-BY-NC-*`, toute licence proprietaire, et toute dependance **sans licence declaree**.

**Perimetre B — outils de developpement et de test** (`devDependencies`, k6, Trivy, Syft).
Ils ne sont jamais distribues avec le systeme et ne creent aucune oeuvre derivee. Toute
licence libre est acceptee, AGPL comprise. Documente pour couper court au faux positif.

**Perimetre C — services d'infrastructure executes comme processus separes** (PostgreSQL,
PostGIS, Redis, Nginx, Grafana, Loki, Prometheus). Communication par protocole reseau, images
non modifiees, aucune liaison au sens du droit d'auteur. Toute licence libre est acceptee.
**Condition impérative** : toute modification du code source de l'un de ces composants
declencherait les obligations de sa licence. Le projet s'interdit donc de les *forker* ; toute
adaptation passe par la configuration.

**Application** : le controle `scripts/gate-licences.mjs` s'execute a chaque PR sur le seul
**perimetre A**, bloquant. Les perimetres B et C sont inventories au SBOM et documentes dans
`docs/conformite/LICENCES.md`, sans blocage.

**Derogation** : une dependance du perimetre A sous licence interdite, sans equivalent
disponible, requiert un avis ecrit de la direction juridique du CENADI et un ADR dedie.

## Consequences

**Positives** — NFR-C9-04 est protegee contre la contamination par copyleft fort a l'endroit
ou elle est reellement menacee. La question « PostGIS est en GPL, est-ce un probleme ? » —
qui reviendra a chaque audit — recoit une reponse ecrite et motivee.

**Negatives / couts** — Certaines dependances utiles seront refusees et devront etre
remplacees. Les licences declarees dans les metadonnees npm sont parfois inexactes : le
controle signale les licences absentes ou ambigues pour arbitrage manuel.

**Irreversibilite** — Nulle, mais une dependance interdite integree puis diffusee serait
juridiquement difficile a retirer. D'ou le controle **a la PR**, pas a la release.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| Interdire toute licence copyleft partout | Eliminerait PostGIS, donc le coeur geospatial du systeme. Juridiquement infonde : un processus separe ne cree pas d'oeuvre derivee. |
| N'appliquer aucun controle | Laisse NFR-C9-03 et NFR-C9-04 invérifiables. Le SDD §4.1 prescrit explicitement le refus des licences non conformes. |
| Controle a la release seulement | Trop tard : la dependance est deja integree et peut-etre deja diffusee. |

## Mise en oeuvre

`scripts/gate-licences.mjs`, `docs/conformite/licences-autorisees.json`,
`docs/conformite/LICENCES.md`, job `conformite-licences` de `.github/workflows/security.yml`.
