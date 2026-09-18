# ADR-037 — Versionner l'API publique et maitriser l'invalidation du cache PWA

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI
- **Perimetre** : technique et **metier**
- **Exigences concernees** : **FR-M7-08**, FR-M7-04 (URI perennes), FR-M2-11 (PWA hors ligne), NFR-C5-01, **art. 26 Loi 2024/001**

## Contexte

Deux mecanismes du systeme ont une consequence metier que les documents n'explicitent pas
completement.

**L'API publique** (module M7) met en oeuvre l'article 26 de la Loi 2024/001 — le fichier
unique des producteurs, accessible au public. Elle sera consommee par des tiers : chercheurs,
partenaires institutionnels, autres administrations. FR-M7-04 exige des URI perennes et
FR-M7-08 un versionnage. Une rupture de contrat non geree casse les integrations de tiers sur
lesquels le CENADI n'a aucune visibilite.

**Le cache PWA** (FR-M2-11) conserve la derniere vue cartographique consultee pour permettre
un usage hors ligne. Mal maitrise, il produit un effet redoutable sur un referentiel
national : **un utilisateur consulte indefiniment une version perimee des donnees sans le
savoir.** Sur un systeme dont la finalite est de dire ou se trouvent les producteurs
d'archives publics, afficher une donnee obsolete sans avertissement est un defaut metier.

## Decision

**API — versionnage par chemin**, forme la plus lisible et la plus facilement mise en cache :
`/api/v1/producteurs`.

| Nature du changement                                                                | Traitement                                                                  |
| ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Ajout d'un champ, d'un point d'entree, d'un filtre optionnel                        | Dans `v1`, sans rupture. Les clients ignorent ce qu'ils ne connaissent pas. |
| Suppression ou renommage d'un champ, changement de type, modification de semantique | **Nouvelle version `v2`**. `v1` maintenue.                                  |
| Correction de securite                                                              | Immediate sur toutes les versions actives.                                  |

**Politique de depreciation** : une version depreciee reste servie **12 mois minimum** apres
l'annonce, avec l'en-tete `Deprecation` (RFC 8594) et un lien `Sunset`. L'annonce est publiee
sur le portail open data et notifiee aux detenteurs de cle API. Douze mois correspondent au
rythme administratif reel des tiers institutionnels camerounais.

**Detection automatique des ruptures** : `scripts/gate-api-contrat.mjs` compare la
specification OpenAPI generee a celle de la derniere release et echoue si une rupture est
introduite sans incrementation de version. Le contrat d'API cesse de dependre de la vigilance
du relecteur.

**URI perennes** (FR-M7-04) : l'identifiant public d'un producteur est son **code unique**
`CMR-<RESEAU>-<MIN>-<STRUCT>-<SEQ>`, jamais son identifiant technique. RG-M1-02 le declare
non modifiable a vie : c'est precisement ce qui fonde la perennite de l'URI. Les identifiants
internes ne doivent apparaitre dans aucune reponse publique.

**PWA — trois regimes de cache**, par nature de ressource :

| Ressource                                   | Strategie                                              | Duree            | Justification                             |
| ------------------------------------------- | ------------------------------------------------------ | ---------------- | ----------------------------------------- |
| Coque applicative (JS, CSS, polices)        | `CacheFirst`, invalidee par le hachage de construction | version          | Change a chaque release                   |
| Tuiles cartographiques OSM                  | `CacheFirst`                                           | 30 jours         | Le fond de carte evolue lentement         |
| Donnees producteurs                         | `NetworkFirst`, repli sur cache                        | **24 h maximum** | Donnees de reference : la fraicheur prime |
| Referentiels (reseaux, ministeres, regions) | `StaleWhileRevalidate`                                 | 7 jours          | Quasi statiques                           |

**Regle metier imperative** : lorsque l'application sert des donnees issues du cache, elle
**affiche systematiquement la date de derniere synchronisation**. Cette obligation prolonge
RG-M3-03, qui impose deja un horodatage de fraicheur sur les tableaux de bord. Aucune donnee
de cache ne doit etre presentee comme etant a jour.

**Au-dela de 7 jours** sans synchronisation, un bandeau explicite avertit l'utilisateur que
les donnees peuvent etre obsoletes et l'invite a se reconnecter.

**Rupture de version de cache** : un incrementeur `CACHE_VERSION` lie a la version applicative
purge l'integralite des caches de donnees a chaque mise a jour majeure, evitant qu'un
utilisateur ne conserve indefiniment un modele de donnees perime.

## Consequences

**Positives** — Les tiers consommateurs de l'API publique disposent d'une garantie de
stabilite compatible avec le calendrier administratif. L'utilisateur hors ligne sait toujours
a quand remontent les donnees qu'il consulte : le systeme ne ment jamais sur sa fraicheur.

**Negatives / couts** — Maintenir deux versions d'API pendant 12 mois a un cout de
developpement et de tests. Le mode hors ligne devient legerement moins « transparent »,
puisqu'il affiche son etat — c'est voulu.

**Irreversibilite** — Moyenne pour l'API : une fois `v1` publiee et consommee par des tiers,
on ne peut plus la retirer sans preavis.

## Alternatives ecartees

| Alternative                       | Raison du rejet                                                                                                                 |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Versionnage par en-tete `Accept`  | Plus elegant en theorie, moins praticable pour des consommateurs institutionnels peu outilles. Complique la mise en cache HTTP. |
| Aucun versionnage                 | Contraire a FR-M7-08. Casse les integrations tierces sans preavis.                                                              |
| Cache PWA sans horodatage visible | Presente des donnees perimees comme courantes. Defaut metier sur un referentiel national.                                       |

## Mise en oeuvre

`apps/backend/src/modules/m7-public-api/`, `scripts/gate-api-contrat.mjs`,
`apps/frontend/src/pwa/service-worker.ts`, `docs/regles-metier/politique-cache.md`,
`docs/conformite/politique-depreciation-api.md`.
