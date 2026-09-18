# Politique de cache PWA

**ADR** : [037](../adr/ADR-037-versionnage-api-pwa.md) · **Exigences** : FR-M2-11, RG-M3-03

## Le risque métier

Le cache hors ligne est une exigence (FR-M2-11) : il rend l'application utilisable
en zone mal couverte. Mal maîtrisé, il produit pourtant un effet redoutable sur un
référentiel national — **un utilisateur consulte indéfiniment une version périmée
des données sans le savoir**.

Sur un système dont la finalité est de dire où se trouvent les producteurs
d'archives publics, afficher une donnée obsolète sans avertissement n'est pas une
imperfection technique : c'est un défaut métier.

## Trois régimes, par nature de ressource

| Ressource                                   | Stratégie                                       | Durée            | Justification                             |
| ------------------------------------------- | ----------------------------------------------- | ---------------- | ----------------------------------------- |
| Coque applicative (JS, CSS, polices)        | `CacheFirst`, invalidée par le hachage de build | version          | Change à chaque release                   |
| Tuiles OpenStreetMap                        | `CacheFirst`                                    | 30 jours         | Le fond de carte évolue lentement         |
| **Données producteurs**                     | `NetworkFirst`, repli sur cache                 | **24 h maximum** | Données de référence : la fraîcheur prime |
| Référentiels (réseaux, ministères, régions) | `StaleWhileRevalidate`                          | 7 jours          | Quasi statiques                           |

## La règle non négociable

**Toute donnée servie depuis le cache s'accompagne de sa date de dernière
synchronisation, affichée à l'écran.**

Cette obligation prolonge RG-M3-03, qui impose déjà un horodatage de fraîcheur
sur les tableaux de bord. Aucune donnée de cache ne doit être présentée comme
étant à jour. Le système ne ment jamais sur sa propre fraîcheur.

Au-delà de **7 jours** sans synchronisation, un bandeau explicite avertit
l'utilisateur et l'invite à se reconnecter.

## Invalidation à la mise à jour

Un compteur `CACHE_VERSION`, lié à la version applicative, purge l'intégralité
des caches de **données** à chaque mise à jour majeure. Sans lui, un utilisateur
peut conserver indéfiniment des données conformes à un modèle qui n'existe plus.

Le service worker lui-même n'est **jamais** mis en cache
(`Cache-Control: no-store`, appliqué par Nginx) : le mettre en cache figerait la
version applicative chez l'utilisateur, sans recours.
