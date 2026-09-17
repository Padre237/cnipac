# Conformité des licences

**ADR** : [025](../adr/ADR-025-licences.md) · **Exigences** : NFR-C9-03, NFR-C9-04

## La question qui revient à chaque audit

« PostGIS est sous GPL-2.0. Le code de CNIPAC doit appartenir à l'État. N'y a-t-il
pas contradiction ? »

**Non.** Le critère juridique pertinent n'est pas la licence en elle-même, mais
le **mode de liaison**. PostGIS s'exécute comme un processus séparé, appelé par
le protocole réseau PostgreSQL, à partir d'une image officielle non modifiée.
Il n'y a pas d'œuvre dérivée au sens du droit d'auteur, donc pas de
contamination du code de CNIPAC.

Le raisonnement vaut pour Grafana et Loki (AGPL-3.0, services séparés) et pour
k6 (AGPL-3.0, outil de test jamais distribué avec le système).

## Trois périmètres, trois régimes

| Périmètre | Contenu | Régime | Contrôle |
|---|---|---|---|
| **A** | Dépendances de production liées au code livré | Allowlist stricte | **Bloquant en PR** |
| **B** | Outils de développement et de test | Toute licence libre | Inventaire SBOM |
| **C** | Services d'infrastructure, processus séparés | Toute licence libre | Inventaire SBOM |

## Périmètre A — allowlist

Autorisées : `MIT` `Apache-2.0` `BSD-2-Clause` `BSD-3-Clause` `ISC` `0BSD`
`Unlicense` `CC0-1.0` `PostgreSQL` `Python-2.0` `BlueOak-1.0.0` `MPL-2.0`

Interdites sans dérogation : `GPL-*` `AGPL-*` `LGPL-*` `SSPL-*` `BUSL-*`
`Elastic-2.0` `CC-BY-NC-*`, toute licence propriétaire, et **toute dépendance
sans licence déclarée**.

`MPL-2.0` est acceptée sous réserve : son copyleft porte sur le fichier, et
n'entraîne aucune obligation tant que les fichiers concernés ne sont pas modifiés.

## La condition impérative

**Le projet s'interdit de forker le code source des composants du périmètre C.**
Toute adaptation passe exclusivement par la configuration. Un fork de PostGIS,
de Grafana ou de Loki déclencherait immédiatement les obligations de leur
licence — et l'analyse ci-dessus ne tiendrait plus.

## Pièces justificatives

Un SBOM CycloneDX est produit à chaque release et archivé sous
`docs/conformite/sbom/<version>/`. C'est la pièce opposable lors de l'audit de
conformité NFR-C9-03, dont le SDD §4.1 prescrit précisément qu'il se fasse
« par inspection des licences via SBOM ».

## Dérogation

Une dépendance du périmètre A sous licence interdite, sans équivalent
disponible, requiert un avis écrit de la direction juridique du CENADI et un ADR
dédié. La dérogation est inscrite dans `licences-autorisees.json`, champ
`exceptions_documentees`, avec sa justification.
