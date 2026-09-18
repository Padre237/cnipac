# ADR-024 — Produire un SBOM CycloneDX et signer les images avec une cle cosign

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + RSSI
- **Perimetre** : technique
- **Exigences concernees** : **NFR-C9-03**, NFR-C9-04, NFR-C3-04, NFR-C5-05, critere C-01 du SDD §4.1

## Contexte

NFR-C9-03 exige une stack « 100 % open source », verifiee par « inventaire des dependances
et licences ». Le SDD §4.1 precise le mode d'evaluation : « inspection des licences **via
SBOM** ». Le SBOM est donc une **piece de conformite contractuelle**, pas un artefact de
confort — et aucun des trois documents ne dit comment il est produit ni ou il est conserve.

S'y ajoute une question que les documents n'abordent pas : comment l'administrateur qui
deploie verifie-t-il que l'image qu'il tire est bien celle que la CI a construite ?

## Decision

**1. SBOM CycloneDX 1.5 en JSON**, genere par Syft a chaque release, pour trois perimetres :

| Perimetre                | Contenu                                               |
| ------------------------ | ----------------------------------------------------- |
| `sbom-backend.cdx.json`  | Image backend complete, systeme de base Alpine inclus |
| `sbom-frontend.cdx.json` | Image frontend, Nginx inclus                          |
| `sbom-source.cdx.json`   | Arbre de dependances du depot (pnpm)                  |

Les SBOM sont **joints a la release GitHub** et **archives dans le depot** sous
`docs/conformite/sbom/vX.Y.Z/`. Ils constituent la piece justificative opposable lors de
l'audit de conformite NFR-C9-03 et lors de la recette P3 (AC-P3-05).

**2. Signature cosign par cle**, et non en mode keyless. Le mode keyless repose sur Fulcio
et Rekor, services publics heberges hors du territoire national, et exige un acces sortant
permanent vers ceux-ci depuis le datacenter — inacceptable au regard de NFR-C9-01 et
difficilement justifiable devant le RSSI. Une paire de cles cosign est generee, la cle
privee stockee en secret d'organisation GitHub et sauvegardee hors ligne par le RSSI, la
cle publique versionnee dans `infra/cosign.pub`.

**3. Verification obligatoire au deploiement.** `scripts/deploy.sh` execute
`cosign verify --key infra/cosign.pub` avant tout demarrage de conteneur. Une image non
signee ou signee par une autre cle **n'est pas deployee**. C'est la barriere qui empeche le
deploiement d'une image construite hors pipeline.

**4. Attestation de provenance** SLSA niveau 2 generee par GitHub Actions, joignant l'image
au commit, au workflow et a l'execution qui l'ont produite.

**5. Rotation** : cle cosign renouvelee annuellement ou immediatement en cas de suspicion.
Procedure dans `docs/runbooks/RB-07-rotation-des-cles.md`.

## Consequences

**Positives** — La conformite NFR-C9-03 devient une piece produite automatiquement a chaque
release plutot qu'un inventaire manuel a reconstituer avant l'audit. La verification de
signature ferme la voie du deploiement d'images non tracees.

**Negatives / couts** — Une cle privee de plus a proteger et a faire tourner. Environ 90
secondes ajoutees a chaque release. Un SBOM par version consomme quelques centaines de
kilo-octets dans le depot ; volume negligeable, valeur probatoire elevee.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                                | Raison du rejet                                                                                              |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| Aucun SBOM, inventaire manuel a la demande | Ne satisfait pas le mode d'evaluation prescrit par le SDD §4.1. Ingérable a 900+ dependances transitives.    |
| cosign keyless (Fulcio / Rekor)            | Dependance a une infrastructure publique etrangere et flux sortants permanents. Incompatible avec NFR-C9-01. |
| SPDX plutot que CycloneDX                  | Equivalent. CycloneDX est mieux outille cote npm et Docker et s'integre nativement a Syft, Grype et Trivy.   |

## Mise en oeuvre

`scripts/generate-sbom.mjs`, `.github/workflows/release.yml`, `infra/cosign.pub`,
`scripts/deploy.sh`, `docs/conformite/sbom/`, `docs/runbooks/RB-07-rotation-des-cles.md`.
