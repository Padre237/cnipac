# ADR-015 — Utiliser GHCR comme registry transitoire, avec cible Harbor CENADI

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI
- **Perimetre** : technique
- **Exigences concernees** : NFR-C5-03, NFR-C5-05, NFR-C9-01

## Contexte

Le SDD §26.4 pousse les images vers `registry.cenadi.cm`. A la date de redaction, **rien
n'atteste de l'existence de ce registre** : ni le SRS §2.6.1 (environnement de production),
ni le SDD §8.3 (dimensionnement des hotes H1/H2/H3) ne prevoient d'hote ni de stockage pour
un registre d'images. Construire le pipeline sur une infrastructure hypothetique bloquerait
le Palier 0 des le Sprint 1.

## Decision

Deux registres, pilotes par une seule variable.

- **P0 a P2** : `ghcr.io/cenadi-cm/cnipac-*`, en visibilite privee.
- **P3, avant la mise en production definitive** : `registry.cenadi.cm` (Harbor recommande
  — libre, Apache 2.0, scan Trivy integre, replication, quotas, RBAC).

Aucun nom de registre n'est ecrit en dur. Les workflows lisent la variable d'organisation
`CNIPAC_REGISTRY` et le secret `CNIPAC_REGISTRY_TOKEN`. La bascule est un changement de
variable, pas un changement de code.

**Politique de retention** : les images `sha-<commit>` sont conservees 90 jours ; les images
correspondant a un tag semver sont conservees **sans limite** — elles constituent le
materiau du rollback (SDD §26.8) et de la reconstruction exigee par NFR-C5-05.

**Regle de reconstructibilite** : toute image poussee est reconstructible a l'identique
depuis le seul commit Git correspondant. Aucune etape de build ne depend d'un artefact
non versionne. Verifiee par le job `build-reproductible` du workflow `release.yml`.

## Consequences

**Positives** — Le pipeline est fonctionnel des le Sprint 1 sans attendre une decision
d'infrastructure. GHCR fournit gratuitement le scan de vulnerabilites et l'attestation de
provenance.

**Negatives / couts** — Les images transitent par une infrastructure etrangere jusqu'a P3.
Elles ne contiennent **aucune donnee** (le code y est deja par ADR-014, les secrets sont
injectes au runtime par ADR-033) : le risque residuel porte sur la confidentialite du code
compile, pas sur les donnees. La mise en place de Harbor est a inscrire au budget P3 :
environ 1 vCPU / 2 Go / 200 Go sur l'hote H3.

**Irreversibilite** — Nulle. La bascule est une variable d'environnement.

## Alternatives ecartees

| Alternative                      | Raison du rejet                                                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Attendre `registry.cenadi.cm`    | Bloque le Palier 0 sur une dependance externe non maitrisee (risque de planning §29.7.3).                     |
| `docker save` / `scp` des images | Rompt la tracabilite par digest exigee par ADR-023 et interdit toute verification de signature.               |
| Registre local sur H1            | H1 est l'hote applicatif de production. Y heberger le registre cree une dependance circulaire au deploiement. |

## Mise en oeuvre

Variables `CNIPAC_REGISTRY`, `CNIPAC_IMAGE_PREFIX` ; `.github/workflows/release.yml` ;
`infra/compose/compose.app.yml` (interpolation `${CNIPAC_REGISTRY}`).
