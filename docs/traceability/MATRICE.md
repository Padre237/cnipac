# Matrice de tracabilite CNIPAC

> **Document genere.** Ne pas modifier a la main — toute edition sera ecrasee
> a la prochaine fusion sur `main`. La source est
> [`exigences.json`](exigences.json) et les identifiants portes par les tests (ADR-035).

Genere le 2026-09-17 — palier courant : **P0**.

## Synthese

| Type | Total | Couvertes | Taux |
| ---- | ----- | --------- | ---- |
| AC   | 30    | 2         | 7 %  |
| FR   | 82    | 0         | 0 %  |
| LOI  | 12    | 0         | 0 %  |
| NFR  | 47    | 6         | 13 % |
| RG   | 34    | 8         | 24 % |
| UC   | 36    | 0         | 0 %  |

## Criteres d'acceptation (SRS chap. 14)

| ID         | Libelle                                                                                                  | Palier | Articles de loi | Etat                | Tests                                                                     |
| ---------- | -------------------------------------------------------------------------------------------------------- | ------ | --------------- | ------------------- | ------------------------------------------------------------------------- |
| `AC-P1-01` | Une soumission Kobo de test parvient en quarantaine CNIPAC en moins de 15 minutes.                       | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-02` | Un archiviste validateur (R-03) peut valider la fiche, qui apparaît immédiatement sur la carte.          | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-03` | La carte affiche 200 producteurs réels géolocalisés, regroupés en clusters au niveau national.           | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-04` | Les filtres réseau/région/ministère sont fonctionnels et croisables.                                     | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-05` | Le tableau de bord national affiche les 4 indicateurs clés à jour.                                       | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-06` | Le RBAC est opérationnel sur 8 rôles ; 5 comptes de test sont créés.                                     | P1     | —               | couverte (unitaire) | `regles-metier.spec.ts`                                                   |
| `AC-P1-07` | Le journal d'audit consigne toutes les opérations sensibles.                                             | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-08` | La carte est utilisable sur connexion 3G simulée (≤ 5 s de chargement).                                  | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-09` | Le code source est versionné sur GitHub institutionnel et bénéficie d'un pipeline CI/CD.                 | P1     | —               | non couverte        | —                                                                         |
| `AC-P1-10` | Aucune vulnérabilité critique ou haute identifiée par scan automatisé OWASP ZAP.                         | P1     | —               | non couverte        | —                                                                         |
| `AC-P2-01` | 1 000 producteurs réels géolocalisés répartis sur 3 régions sont chargés.                                | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-02` | Au moins 10 points focaux désignés peuvent se connecter et proposer des mises à jour.                    | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-03` | L'application est utilisable hors ligne en mode PWA (dernière vue cartographique consultée).             | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-04` | L'API REST est documentée Swagger et propose les endpoints producteurs/statistiques/référentiels.        | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-05` | Un export EAC-CPF valide est produit pour toute fiche validée.                                           | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-06` | L'interface est disponible en français et en anglais.                                                    | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-07` | Le MFA est opérationnel pour les rôles administrateurs.                                                  | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-08` | Le pentest mené par un tiers ne révèle aucune vulnérabilité critique.                                    | P2     | —               | non couverte        | —                                                                         |
| `AC-P2-09` | Le système supporte 200 utilisateurs simultanés sans dégradation perceptible.                            | P2     | —               | couverte (test)     | `01-carte-initiale.js`, `02-fiche-producteur.js`, `03-tableau-de-bord.js` |
| `AC-P2-10` | L'audit d'accessibilité atteint 90% de critères WCAG 2.1 AA testés.                                      | P2     | —               | non couverte        | —                                                                         |
| `AC-P3-01` | Le jeu de données complet collecté est intégré (≥ 80 % de la cible 12 000-15 000).                       | P3     | Art. 55         | non couverte        | —                                                                         |
| `AC-P3-02` | Le portail open data est ouvert au public et propose des téléchargements directs.                        | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-03` | L'API publique est documentée, versionnée et accessible sans authentification sur les endpoints publics. | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-04` | Le système est hébergé sur l'infrastructure de production définitive (CENADI).                           | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-05` | L'audit de sécurité indépendant valide la conformité à C3 et C4 (sécurité, confidentialité).             | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-06` | Le système tient une charge de 500 utilisateurs simultanés sans dégradation.                             | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-07` | Au moins 100 points focaux sont actifs et au moins 50 propositions de mises à jour ont été traitées.     | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-08` | Les sauvegardes externalisées sont opérationnelles et un exercice de restauration est passant.           | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-09` | La documentation utilisateur, administrateur et développeur est complète et accessible.                  | P3     | —               | non couverte        | —                                                                         |
| `AC-P3-10` | Le rapport national annuel sur l'état des archives publiques est produit en démonstration.               | P3     | —               | non couverte        | —                                                                         |

## Exigences fonctionnelles (SRS chap. 9)

| ID         | Libelle                                                                                                                            | Palier | Articles de loi  | Etat         | Tests |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------------- | ------------ | ----- |
| `FR-M1-01` | Le système DOIT se connecter au serveur KoboToolbox via l'API OAuth2/Token sécurisée et récupérer périodiquement les nouvelles sou | P1     | Art. 21          | non couverte | —     |
| `FR-M1-02` | Le système DOIT permettre la configuration du ou des formulaires Kobo à synchroniser, ainsi que la fréquence de synchronisation (e | P1     | Art. 21          | non couverte | —     |
| `FR-M1-03` | Le système DOIT valider chaque soumission entrante contre un schéma de données défini (champs obligatoires présents, types respect | P1     | —                | non couverte | —     |
| `FR-M1-04` | Le système DOIT détecter et traiter les doublons potentiels (même structure soumise deux fois) à l'aide d'une stratégie déterminis | P1     | —                | non couverte | —     |
| `FR-M1-05` | Le système DOIT placer toute soumission valide en zone de QUARANTAINE jusqu'à validation explicite par un archiviste validateur (R | P1     | —                | non couverte | —     |
| `FR-M1-06` | Le système DOIT générer pour chaque soumission validée un identifiant unique normalisé (code producteur) selon le format CMR-<RÉSE | P1     | —                | non couverte | —     |
| `FR-M1-07` | Le système DOIT produire un journal d'ingestion exhaustif (soumissions reçues, validées, rejetées, mises en quarantaine, doublons  | P1     | —                | non couverte | —     |
| `FR-M1-08` | Le système DOIT préserver une référence immuable vers la soumission Kobo d'origine (identifiant Kobo, instanceID, horodatage de so | P1     | —                | non couverte | —     |
| `FR-M1-09` | Le système DOIT gérer les échecs de synchronisation (timeout, erreur réseau, indisponibilité Kobo) par une stratégie de réessai ex | P1     | —                | non couverte | —     |
| `FR-M1-10` | Le système DOIT permettre à un administrateur métier (R-02) de lancer manuellement une synchronisation à la demande (« Synchronise | P1     | —                | non couverte | —     |
| `FR-M1-11` | Le système PEUT proposer un mode de prévisualisation des soumissions en quarantaine avec un masquage des données sensibles (donnée | P2     | —                | non couverte | —     |
| `FR-M1-12` | Le système DOIT gérer les mises à jour de fiches existantes par soumission Kobo (mise à jour incrémentale) en préservant l'histori | P2     | —                | non couverte | —     |
| `FR-M2-01` | Le système DOIT afficher une carte interactive du Cameroun basée sur OpenStreetMap, centrée sur le pays au chargement initial.     | P1     | Art. 22, Art. 26 | non couverte | —     |
| `FR-M2-02` | Le système DOIT afficher les producteurs d'archives sous forme de marqueurs ponctuels géolocalisés, avec une icône différenciée se | P1     | —                | non couverte | —     |
| `FR-M2-03` | Le système DOIT regrouper visuellement les marqueurs en grappes (clusters) lorsque la densité dépasse un seuil configurable, avec  | P1     | —                | non couverte | —     |
| `FR-M2-04` | Le système DOIT permettre à l'utilisateur de filtrer les producteurs affichés sur la carte selon les critères suivants : réseau ar | P1     | —                | non couverte | —     |
| `FR-M2-05` | Le système DOIT afficher au clic sur un marqueur une fiche synthétique du producteur (sigle, intitulé complet, sigles, coordonnées | P1     | —                | non couverte | —     |
| `FR-M2-06` | Le système DOIT proposer depuis la fiche synthétique un lien vers la fiche détaillée complète (vue complète des 7 sections du dict | P1     | —                | non couverte | —     |
| `FR-M2-07` | Le système DOIT proposer un mode « recherche textuelle » permettant de retrouver un producteur par son nom, son sigle, ou un mot-c | P1     | —                | non couverte | —     |
| `FR-M2-08` | Le système DOIT proposer plusieurs fonds de carte : OpenStreetMap standard, image satellite (si disponible), carte simplifiée (mod | P2     | —                | non couverte | —     |
| `FR-M2-09` | Le système DOIT proposer une couche d'affichage des limites administratives (régions, départements, communes) activable/désactivab | P2     | —                | non couverte | —     |
| `FR-M2-10` | Le système DOIT être consultable sans authentification en mode lecture publique limitée (carte + fiche synthétique uniquement, san | P1     | —                | non couverte | —     |
| `FR-M2-11` | Le système DOIT être déployé sous forme de Progressive Web App (PWA) avec mise en cache des ressources statiques et de la dernière | P2     | —                | non couverte | —     |
| `FR-M2-12` | Le système DOIT permettre l'export de la sélection courante de producteurs au format CSV et GeoJSON, pour les utilisateurs disposa | P2     | —                | non couverte | —     |
| `FR-M2-13` | Le système PEUT proposer une visualisation par carte choroplèthe (densité de producteurs par région ou par département).           | P3     | —                | non couverte | —     |
| `FR-M2-14` | Le système DOIT respecter les standards d'accessibilité WCAG 2.1 niveau AA pour la navigation cartographique (alternatives clavier | P2     | —                | non couverte | —     |
| `FR-M3-01` | Le système DOIT afficher sur la page d'accueil authentifiée un tableau de bord national présentant au minimum : nombre total de pr | P1     | Art. 16          | non couverte | —     |
| `FR-M3-02` | Le système DOIT proposer un tableau de bord par réseau archivistique (les 9 réseaux du SND30) avec ses indicateurs propres (nombre | P1     | —                | non couverte | —     |
| `FR-M3-03` | Le système DOIT proposer un tableau de bord par région et par département avec les mêmes indicateurs déclinés au territoire.       | P1     | —                | non couverte | —     |
| `FR-M3-04` | Le système DOIT proposer un indicateur composite de maturité archivistique (échelle de 0 à 100) calculé à partir des données de la | P1     | Art. 14          | non couverte | —     |
| `FR-M3-05` | Le système DOIT permettre l'export des tableaux de bord au format PDF (rapport mis en forme) et Excel (données brutes) pour les ut | P1     | Art. 13          | non couverte | —     |
| `FR-M3-06` | Le système DOIT proposer des tableaux croisés dynamiques permettant de croiser au minimum deux dimensions (par exemple : réseau ×  | P2     | —                | non couverte | —     |
| `FR-M3-07` | Le système DOIT archiver mensuellement un instantané de chaque tableau de bord national afin de permettre l'analyse de l'évolution | P2     | —                | non couverte | —     |
| `FR-M3-08` | Le système PEUT proposer des alertes automatiques lorsque des indicateurs franchissent un seuil défini (par exemple : couverture d | P3     | Art. 14, Art. 31 | non couverte | —     |
| `FR-M3-09` | Le système DOIT proposer une représentation graphique pour chaque indicateur clé (histogramme, secteurs, courbe de tendance) avec  | P1     | —                | non couverte | —     |
| `FR-M3-10` | Le système DOIT permettre la génération d'un « Rapport national annuel sur l'état des archives publiques » à partir des données di | P3     | Art. 31          | non couverte | —     |
| `FR-M4-01` | Le système DOIT proposer une vue détaillée de chaque producteur structurée selon les sept (7) sections du questionnaire (identific | P1     | Art. 16          | non couverte | —     |
| `FR-M4-02` | Le système DOIT permettre à un archiviste validateur (R-03) ou un administrateur métier (R-02) de valider une fiche en quarantaine | P1     | —                | non couverte | —     |
| `FR-M4-03` | Le système DOIT permettre l'édition champ par champ d'une fiche validée par les rôles R-02 et R-03, avec génération automatique d' | P1     | —                | non couverte | —     |
| `FR-M4-04` | Le système DOIT préserver l'historique intégral des versions d'une fiche, avec la possibilité de comparer deux versions champ par  | P2     | —                | non couverte | —     |
| `FR-M4-05` | Le système DOIT permettre la consultation de la fiche détaillée par tout utilisateur authentifié disposant du droit P-M4-02 (R-02, | P1     | —                | non couverte | —     |
| `FR-M4-06` | Le système DOIT permettre à un point focal (R-05) de proposer une mise à jour de la fiche de SA structure uniquement, par soumissi | P2     | —                | non couverte | —     |
| `FR-M4-07` | Le système DOIT permettre à un archiviste validateur d'examiner, d'accepter, de modifier ou de rejeter chaque proposition de mise  | P2     | —                | non couverte | —     |
| `FR-M4-08` | Le système DOIT permettre l'archivage logique (statut « ARCHIVÉE ») d'une fiche obsolète (structure dissoute, fusionnée) sans supp | P2     | —                | non couverte | —     |
| `FR-M4-09` | Le système DOIT permettre la fusion contrôlée de deux fiches détectées comme doublons, avec arbitrage champ par champ et conservat | P3     | Art. 13          | non couverte | —     |
| `FR-M4-10` | Le système DOIT permettre la SUPPRESSION PHYSIQUE d'une fiche uniquement par le super-administrateur (R-01), uniquement sur les fi | P3     | —                | non couverte | —     |
| `FR-M4-11` | Le système DOIT proposer une recherche avancée multicritères sur l'ensemble des fiches producteurs (recherche combinant plusieurs  | P2     | —                | non couverte | —     |
| `FR-M4-12` | Le système PEUT proposer un module d'annotation collaborative permettant à plusieurs archivistes de laisser des notes internes sur | P3     | —                | non couverte | —     |
| `FR-M4-13` | Le système DOIT permettre l'attachement de pièces jointes documentaires à une fiche (organigramme, arrêté de création, photos du l | P2     | —                | non couverte | —     |
| `FR-M4-14` | Le système DOIT produire une notice d'autorité conforme à la norme ISAAR-CPF (forme autorisée du nom, types d'entité, dates d'exis | P2     | —                | non couverte | —     |
| `FR-M5-01` | Le système DOIT permettre à un point focal désigné (R-05) de se connecter à un espace contributeur dédié, après authentification r | P2     | Art. 19          | non couverte | —     |
| `FR-M5-02` | Le système DOIT afficher au point focal la fiche actuelle de SA structure uniquement, avec mise en évidence des champs périmés ou  | P2     | Art. 19          | non couverte | —     |
| `FR-M5-03` | Le système DOIT permettre au point focal de proposer des modifications champ par champ via un formulaire de mise à jour structuré. | P2     | Art. 19          | non couverte | —     |
| `FR-M5-04` | Le système DOIT placer toute proposition de mise à jour en file d'attente de validation, sans l'appliquer immédiatement à la fiche | P2     | Art. 19          | non couverte | —     |
| `FR-M5-05` | Le système DOIT permettre au point focal de joindre des pièces justificatives à sa proposition (par exemple : arrêté nominatif réc | P2     | Art. 19          | non couverte | —     |
| `FR-M5-06` | Le système DOIT notifier le point focal du statut de sa proposition (acceptée, refusée, demande de complément) par e-mail.         | P2     | Art. 19          | non couverte | —     |
| `FR-M5-07` | Le système DOIT permettre à un point focal de signaler une erreur ou un changement majeur affectant sa structure (changement de tu | P3     | —                | non couverte | —     |
| `FR-M5-08` | Le système DOIT limiter le débit de propositions par compte (par exemple : maximum 10 propositions par jour par point focal) pour  | P2     | —                | non couverte | —     |
| `FR-M5-09` | Le système PEUT proposer un mécanisme de réputation des points focaux (taux d'acceptation, qualité des propositions) afin d'identi | P3     | —                | non couverte | —     |
| `FR-M5-10` | Le système DOIT permettre la désignation officielle d'un point focal par un administrateur métier (R-02), sur la base d'une lettre | P2     | —                | non couverte | —     |
| `FR-M6-01` | Le système DOIT proposer une interface d'administration des comptes utilisateurs réservée aux rôles R-01 et R-02 (création, modifi | P1     | —                | non couverte | —     |
| `FR-M6-02` | Le système DOIT permettre l'attribution et la révocation de rôles à un utilisateur. L'attribution multiple est autorisée dans la l | P1     | —                | non couverte | —     |
| `FR-M6-03` | Le système DOIT imposer une politique de mot de passe robuste : minimum 12 caractères, au moins 1 majuscule, 1 minuscule, 1 chiffr | P1     | —                | non couverte | —     |
| `FR-M6-04` | Le système DOIT proposer une authentification à double facteur (MFA) par TOTP ou e-mail pour les rôles R-01, R-02 et R-03, et la r | P2     | —                | non couverte | —     |
| `FR-M6-05` | Le système DOIT verrouiller un compte après 5 tentatives infructueuses de connexion en 10 minutes, et notifier le titulaire par e- | P1     | —                | non couverte | —     |
| `FR-M6-06` | Le système DOIT produire un journal d'audit exhaustif consignant : connexions (réussies/échouées), créations/modifications/suppres | P1     | —                | non couverte | —     |
| `FR-M6-07` | Le système DOIT garantir l'intégrité du journal d'audit (non modifiable, non purgeable par les utilisateurs, conservation minimale | P1     | —                | non couverte | —     |
| `FR-M6-08` | Le système DOIT proposer un tableau de bord de supervision technique pour le rôle R-01 : état des services, charge, file d'attente | P2     | Art. 58          | non couverte | —     |
| `FR-M6-09` | Le système DOIT permettre la configuration centralisée des paramètres métier : seuils d'alerte, périodicité de synchronisation, fo | P1     | Art. 32          | non couverte | —     |
| `FR-M6-10` | Le système DOIT proposer une fonction d'export du journal d'audit au format CSV, restreinte aux rôles R-01 et R-02, et tracer chaq | P1     | Art. 32          | non couverte | —     |
| `FR-M6-11` | Le système DOIT chiffrer en transit (TLS 1.3) toute communication entre le client et le serveur, et entre les services internes.   | P1     | —                | non couverte | —     |
| `FR-M6-12` | Le système DOIT chiffrer au repos les données sensibles (données nominatives, journaux d'audit, pièces jointes) selon AES-256.     | P1     | —                | non couverte | —     |
| `FR-M6-13` | Le système DOIT mettre en œuvre une protection contre les attaques applicatives courantes : injection SQL, XSS, CSRF, SSRF, déni d | P1     | —                | non couverte | —     |
| `FR-M6-14` | Le système DOIT permettre l'expiration et le renouvellement périodique des jetons d'authentification (JWT) : durée de vie d'accès  | P1     | —                | non couverte | —     |
| `FR-M7-01` | Le système DOIT exposer ses fonctionnalités sous forme d'une API RESTful documentée (OpenAPI 3.x), couvrant a minima : liste des p | P2     | Art. 22, Art. 26 | non couverte | —     |
| `FR-M7-02` | Le système DOIT authentifier les appels API via des clés API ou des jetons OAuth2 selon le profil du consommateur, avec quotas con | P2     | —                | non couverte | —     |
| `FR-M7-03` | Le système DOIT exposer les données ouvertes (non sensibles) au format JSON, GeoJSON et CSV, en conformité avec la philosophie « o | P3     | Art. 26          | non couverte | —     |
| `FR-M7-04` | Le système DOIT exporter les notices d'autorité au format EAC-CPF (XML), conformément à la norme ISAAR-CPF.                        | P2     | —                | non couverte | —     |
| `FR-M7-05` | Le système DOIT exposer un endpoint de statistiques agrégées (par réseau, par région) sans authentification, en respectant l'anony | P3     | —                | non couverte | —     |
| `FR-M7-06` | Le système DOIT publier un identifiant pérenne (URI) pour chaque producteur, sous la forme https://cnipac.cm/producteurs/<code_pro | P2     | —                | non couverte | —     |
| `FR-M7-07` | Le système PEUT proposer une interface GraphQL en complément de l'API REST, pour les besoins de requêtes complexes (interrogation  | P3     | —                | non couverte | —     |
| `FR-M7-08` | Le système DOIT versionner son API (préfixe /v1/, /v2/) et garantir une rétrocompatibilité de 24 mois minimum pour toute API en ve | P2     | —                | non couverte | —     |

## Conformite a la Loi n 2024/001 (SRS chap. 15)

| Article | Disposition                                                       | Exigences de couverture                                              |
| ------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| Art. 13 | Duree de conservation selon la valeur des archives                | NFR-C4-03, FR-M3-05, FR-M4-09                                        |
| Art. 14 | Obligations des producteurs d'archives                            | FR-M3-08, FR-M3-04                                                   |
| Art. 16 | Role des Archives Nationales du Cameroun                          | FR-M3-01, FR-M4-01                                                   |
| Art. 19 | Correspondants archives et leurs missions                         | FR-M5-01, FR-M5-02, FR-M5-03, FR-M5-04, FR-M5-05, FR-M5-06, RG-M5-03 |
| Art. 21 | Collecte et pre-archivage                                         | FR-M1-01, FR-M1-02, RG-M1-01                                         |
| Art. 22 | Communication des archives au public                              | NFR-C4-01, RG-M7-01, FR-M2-01, FR-M7-01                              |
| Art. 26 | Fichier unique et accessible des producteurs d'archives publiques | FR-M7-01, FR-M7-03, FR-M2-01, RG-M2-01                               |
| Art. 31 | Controle archivistique                                            | FR-M3-08, FR-M3-10                                                   |
| Art. 32 | Journal d'audit immuable / controle par inspecteurs assermentes   | NFR-C3-05, FR-M6-09, FR-M6-10, RG-M6-03                              |
| Art. 4  | Archives publiques : bien inalienable et imprescriptible          | RG-TR-02, RG-TR-01                                                   |
| Art. 55 | Delai de 18 mois pour la mise en conformite                       | AC-P3-01                                                             |
| Art. 58 | Publication au Journal Officiel en francais et en anglais         | NFR-C8-01, FR-M6-08                                                  |

## Exigences non fonctionnelles (SRS chap. 10)

| ID          | Libelle                                                                                                                            | Palier | Articles de loi | Etat                | Tests                   |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------ | --------------- | ------------------- | ----------------------- |
| `NFR-C1-01` | Le système DOIT afficher la carte initiale (vue Cameroun) en moins de 5 secondes sur une connexion 3G de référence (1 Mbit/s, 100  | —      | —               | couverte (E2E)      | `playwright.config.ts`  |
| `NFR-C1-02` | Le système DOIT répondre à toute requête API authentifiée standard en moins de 800 ms en P95.                                      | —      | —               | non couverte        | —                       |
| `NFR-C1-03` | Le système DOIT supporter 200 utilisateurs simultanés sans dégradation perceptible des performances (temps de réponse < +20 %).    | —      | —               | non couverte        | —                       |
| `NFR-C1-04` | Le système DOIT gérer un référentiel d'au moins 15 000 producteurs sans dégradation de la navigation cartographique.               | —      | —               | non couverte        | —                       |
| `NFR-C1-05` | Le système DOIT permettre l'export d'un fichier de 10 000 producteurs au format CSV en moins de 30 secondes.                       | —      | —               | non couverte        | —                       |
| `NFR-C1-06` | L'application PWA DOIT consommer moins de 5 Mo de données pour un parcours utilisateur type (carte + 10 fiches).                   | —      | —               | non couverte        | —                       |
| `NFR-C1-07` | Le système DOIT charger l'application initiale (bundle JS+CSS) en moins de 2 Mo compressé.                                         | —      | —               | non couverte        | —                       |
| `NFR-C2-01` | Le système DOIT être disponible 99,5 % du temps en heures ouvrées (lundi-vendredi 07h-19h Yaoundé).                                | —      | —               | non couverte        | —                       |
| `NFR-C2-02` | Le système DOIT être disponible 99,0 % du temps sur 24h/24, 7j/7, en moyenne mensuelle.                                            | —      | —               | non couverte        | —                       |
| `NFR-C2-03` | Le système DOIT être restauré dans un délai maximum de 4 heures après un incident majeur (RTO).                                    | —      | —               | non couverte        | —                       |
| `NFR-C2-04` | Le système DOIT garantir une perte de données maximale de 1 heure en cas d'incident majeur (RPO).                                  | —      | —               | non couverte        | —                       |
| `NFR-C2-05` | Les sauvegardes DOIVENT être effectuées au minimum toutes les 24 heures, conservées 30 jours en local et 12 mois en externalisé.   | —      | —               | non couverte        | —                       |
| `NFR-C2-06` | Le système DOIT tolérer la perte d'un nœud applicatif sans interruption de service (architecture redondée à partir de P3).         | —      | —               | non couverte        | —                       |
| `NFR-C3-01` | Toutes les communications externes DOIVENT utiliser TLS 1.3 ou supérieur.                                                          | —      | —               | non couverte        | —                       |
| `NFR-C3-02` | Les données nominatives et journaux d'audit DOIVENT être chiffrés au repos selon AES-256.                                          | —      | —               | non couverte        | —                       |
| `NFR-C3-03` | Le système DOIT être soumis à un test d'intrusion avant chaque mise en production majeure (P1, P2, P3) et au moins une fois par an | —      | —               | non couverte        | —                       |
| `NFR-C3-04` | Aucune vulnérabilité de criticité CRITIQUE ou HAUTE (CVSS ≥ 7) ne DOIT subsister à la mise en production.                          | —      | —               | non couverte        | —                       |
| `NFR-C3-05` | Le journal d'audit DOIT être conservé pendant au moins 5 ans, sans possibilité de modification ou de purge anticipée.              | —      | Art. 32         | non couverte        | —                       |
| `NFR-C3-06` | Les mots de passe DOIVENT être stockés selon l'algorithme Argon2id ou bcrypt avec coût ≥ 12.                                       | —      | —               | non couverte        | —                       |
| `NFR-C3-07` | Le système DOIT mettre en œuvre une politique de durcissement des en-têtes HTTP (CSP, HSTS, X-Content-Type-Options, X-Frame-Option | —      | —               | non couverte        | —                       |
| `NFR-C3-08` | Le système DOIT être protégé contre les attaques de force brute par rate limiting (5 tentatives/10 minutes par IP et par compte).  | —      | —               | non couverte        | —                       |
| `NFR-C4-01` | Les données nominatives (noms, prénoms, téléphones, e-mails des correspondants) NE DOIVENT PAS être exposées publiquement dans la  | —      | Art. 22         | non couverte        | —                       |
| `NFR-C4-02` | Le système DOIT proposer une fonction d'export anonymisé pour les usages de recherche (suppression des données nominatives, généra | —      | —               | non couverte        | —                       |
| `NFR-C4-03` | Les données collectées DOIVENT être conservées tant que le producteur existe et 5 ans après sa dissolution, conformément à l'artic | —      | Art. 13         | non couverte        | —                       |
| `NFR-C4-04` | Toute extraction massive de données (> 100 fiches) DOIT être tracée nominativement et notifiée à l'administrateur métier.          | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `NFR-C5-01` | Le système DOIT respecter les standards ouverts : OpenAPI 3.x, GeoJSON, CSV (RFC 4180), JSON, XML, EAC-CPF.                        | —      | —               | non couverte        | —                       |
| `NFR-C5-02` | Le système DOIT fonctionner sur les principaux navigateurs récents : Chrome, Firefox, Edge, Safari (2 dernières versions majeures) | —      | —               | couverte (E2E)      | `playwright.config.ts`  |
| `NFR-C5-03` | Le système DOIT être déployable sur infrastructure Linux standard (Ubuntu LTS, Debian) via conteneurs Docker.                      | —      | —               | non couverte        | —                       |
| `NFR-C5-04` | Les données géographiques DOIVENT être stockées dans le système de coordonnées de référence WGS84 (EPSG:4326).                     | —      | —               | non couverte        | —                       |
| `NFR-C5-05` | Le système DOIT pouvoir être réinstallé intégralement à partir des seuls dépôts de code source et des sauvegardes (pas de dépendan | —      | —               | non couverte        | —                       |
| `NFR-C6-01` | Le code source DOIT respecter une couverture de tests automatisés d'au moins 70 % sur les modules métier.                          | —      | —               | non couverte        | —                       |
| `NFR-C6-02` | Le code source DOIT être versionné dans un dépôt Git (GitHub) hébergé sous le compte institutionnel CENADI/ANC, accessible aux équ | —      | —               | non couverte        | —                       |
| `NFR-C6-03` | Le système DOIT disposer d'un pipeline d'intégration continue (CI/CD) automatisant : lint, tests unitaires, scan de dépendances, b | —      | —               | non couverte        | —                       |
| `NFR-C6-04` | Le code DOIT respecter les conventions de nommage et style définies dans le guide de code (ESLint, Prettier en frontend ; règles é | —      | —               | non couverte        | —                       |
| `NFR-C6-05` | Chaque module fonctionnel DOIT être documenté : description, dépendances, configuration, points d'extension.                       | —      | —               | non couverte        | —                       |
| `NFR-C6-06` | Le système DOIT pouvoir être étendu à 50 000 producteurs sans réingénierie majeure (montée en charge linéaire prouvée).            | —      | —               | non couverte        | —                       |
| `NFR-C7-01` | Le système DOIT respecter les standards d'accessibilité WCAG 2.1 niveau AA.                                                        | —      | —               | non couverte        | —                       |
| `NFR-C7-02` | Le système DOIT être utilisable au clavier seul (navigation, formulaires, carte).                                                  | —      | —               | non couverte        | —                       |
| `NFR-C7-03` | Le système DOIT respecter un contraste minimum de 4,5:1 pour le texte normal et 3:1 pour le texte large.                           | —      | —               | non couverte        | —                       |
| `NFR-C7-04` | Le système DOIT être responsive et utilisable sur smartphones, tablettes et postes fixes (résolution mini supportée 360×640).      | —      | —               | couverte (E2E)      | `playwright.config.ts`  |
| `NFR-C8-01` | Le système DOIT proposer une interface en français en P1, et en anglais à partir de P2 — les deux langues officielles du Cameroun. | —      | Art. 58         | couverte (unitaire) | `regles-metier.spec.ts` |
| `NFR-C8-02` | Le système DOIT gérer correctement les caractères Unicode (UTF-8) y compris les caractères diacritiques utilisés dans les langues  | —      | —               | non couverte        | —                       |
| `NFR-C8-03` | Les dates et horaires DOIVENT être affichés au format Cameroun (jj/mm/aaaa, fuseau Africa/Douala = UTC+1).                         | —      | —               | couverte (E2E)      | `playwright.config.ts`  |
| `NFR-C9-01` | Les données du système CNIPAC DOIVENT être hébergées sur une infrastructure située au Cameroun, opérée par une administration publ | —      | —               | non couverte        | —                       |
| `NFR-C9-02` | Aucune donnée nominative ou journal d'audit NE DOIT être transmis ou répliqué hors du territoire national, sauf dérogation express | —      | —               | non couverte        | —                       |
| `NFR-C9-03` | L'ensemble des technologies utilisées DOIT être open source ou libre de redevance, conformément aux orientations de souveraineté n | —      | —               | non couverte        | —                       |
| `NFR-C9-04` | Le code source DOIT appartenir intégralement à l'État du Cameroun (CENADI mandataire), avec cession explicite par tous les contrib | —      | —               | non couverte        | —                       |

## Regles de gestion (SRS chap. 11)

| ID         | Libelle                                                                                                                            | Palier | Articles de loi | Etat                | Tests                   |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------ | --------------- | ------------------- | ----------------------- |
| `RG-M1-01` | Toute soumission KoboToolbox passe obligatoirement par la zone de QUARANTAINE avant publication dans CNIPAC.                       | —      | Art. 21         | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M1-02` | Le code unique du producteur (CMR-<RÉSEAU>-<MIN>-<STRUCT>-<SEQ>) est généré automatiquement par le système au moment de la validat | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M1-03` | Deux soumissions sont considérées comme doublons potentiels si elles partagent le même triplet (sigle structure, ministère de tute | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M1-04` | La référence à la soumission KoboToolbox d'origine est conservée à vie ; elle ne peut être effacée même en cas de modification de  | —      | —               | non couverte        | —                       |
| `RG-M1-05` | Le statut d'une fiche évolue selon un automate : NOUVELLE → QUARANTAINE → VALIDÉE → (ÉDITÉE)* → (ARCHIVÉE). Aucune transition arri | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M2-01` | Seuls les producteurs au statut VALIDÉE ou ÉDITÉE sont affichés sur la carte. Les fiches en quarantaine, archivées ou rejetées n'a | —      | Art. 26         | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M2-02` | La carte publique non authentifiée n'affiche que les champs non sensibles d'une fiche producteur (sigle, intitulé, coordonnées géo | —      | —               | non couverte        | —                       |
| `RG-M2-03` | Les producteurs sans coordonnées géographiques valides (latitude/longitude absentes ou hors enveloppe Cameroun) ne sont PAS affich | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M2-04` | Le réseau archivistique d'un producteur est calculé automatiquement à partir de son ministère de tutelle et de son statut administ | —      | —               | non couverte        | —                       |
| `RG-M3-01` | L'indice de maturité archivistique est calculé selon la formule pondérée définie en annexe F (présence d'un service d'archives 25% | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M3-02` | Les tableaux de bord publics n'agrègent que des données ; aucun enregistrement individuel n'est exposé. Le seuil minimal d'agrégat | —      | —               | couverte (unitaire) | `regles-metier.spec.ts` |
| `RG-M3-03` | Les indicateurs nationaux sont rafraîchis quotidiennement à 03h00 UTC+1. Les utilisateurs voient toujours un horodatage de dernièr | —      | —               | non couverte        | —                       |
| `RG-M4-01` | Toute modification d'une fiche validée produit automatiquement une nouvelle version. La version précédente est conservée, accessib | —      | —               | non couverte        | —                       |
| `RG-M4-02` | Une fiche ne peut être supprimée physiquement qu'après archivage logique depuis au moins 12 mois, et uniquement par le super-admin | —      | —               | non couverte        | —                       |
| `RG-M4-03` | La fusion de deux fiches doublons est nominative : l'archiviste validateur choisit champ par champ la valeur retenue. Les deux fic | —      | —               | non couverte        | —                       |
| `RG-M4-04` | Une notice d'autorité ISAAR-CPF est produite pour tout producteur validé. La forme autorisée du nom respecte les conventions ANC ( | —      | —               | non couverte        | —                       |
| `RG-M4-05` | Les modifications de champs structurants (ministère de tutelle, dénomination officielle, statut administratif) requièrent une PIÈC | —      | —               | non couverte        | —                       |
| `RG-M5-01` | Un point focal archives est rattaché à UNE ET UNE SEULE structure productrice. Il ne peut consulter ni modifier les données d'une  | —      | —               | non couverte        | —                       |
| `RG-M5-02` | Toute proposition de mise à jour d'un point focal NE MODIFIE PAS la fiche publiée tant qu'elle n'a pas été validée par un archivis | —      | —               | non couverte        | —                       |
| `RG-M5-03` | L'ouverture d'un compte point focal est conditionnée à la réception d'une lettre officielle de désignation signée par le responsab | —      | Art. 19         | non couverte        | —                       |
| `RG-M5-04` | Un point focal qui n'a pas connecté son compte depuis 12 mois est automatiquement désactivé. Sa réactivation requiert une nouvelle | —      | —               | non couverte        | —                       |
| `RG-M5-05` | Une proposition de mise à jour reste en file d'attente au maximum 30 jours. Au-delà, elle est automatiquement archivée comme NON T | —      | —               | non couverte        | —                       |
| `RG-M6-01` | Un utilisateur peut cumuler PLUSIEURS rôles, sauf dans les cas de conflit (par exemple : le rôle R-01 super-administrateur est exc | —      | —               | non couverte        | —                       |
| `RG-M6-02` | L'attribution d'un rôle est une action sensible : elle est tracée dans le journal d'audit, et notifiée à l'utilisateur concerné pa | —      | —               | non couverte        | —                       |
| `RG-M6-03` | Le journal d'audit est immuable : aucun rôle (y compris R-01) ne peut éditer ou supprimer une entrée. La rotation se fait uniqueme | —      | Art. 32         | non couverte        | —                       |
| `RG-M6-04` | Le super-administrateur (R-01) est restreint à un nombre maximal de 3 comptes nominatifs (chef DEL, chef DEP, suppléant désigné).  | —      | —               | non couverte        | —                       |
| `RG-M7-01` | L'API publique n'expose JAMAIS de données nominatives. Toute donnée nominative est filtrée à la couche API publique.               | —      | Art. 22         | non couverte        | —                       |
| `RG-M7-02` | L'API authentifiée applique les mêmes contrôles d'accès que l'interface web (RBAC homogène). Aucun endpoint API ne dispose de droi | —      | —               | non couverte        | —                       |
| `RG-M7-03` | Chaque consommateur API est identifié par une clé ou un jeton ; les appels anonymes sont autorisés uniquement sur les endpoints ex | —      | —               | non couverte        | —                       |
| `RG-M7-04` | Une dépréciation d'API est annoncée au moins 12 mois avant retrait. Pendant la période, des en-têtes de dépréciation signalent l'o | —      | —               | non couverte        | —                       |
| `RG-TR-01` | Tous les horodatages stockés dans le système sont en UTC. L'affichage s'effectue au fuseau Africa/Douala (UTC+1).                  | —      | Art. 4          | non couverte        | —                       |
| `RG-TR-02` | Les données du système CNIPAC sont la propriété de l'État du Cameroun, représenté par le CENADI et les Archives Nationales.        | —      | Art. 4          | non couverte        | —                       |
| `RG-TR-03` | Toute opération qui modifie l'état du système (création, modification, suppression, attribution de rôle, validation) génère un évé | —      | —               | non couverte        | —                       |
| `RG-TR-04` | Le système s'aligne sur le calendrier administratif camerounais : exercices budgétaires annuels (1er janvier - 31 décembre), jours | —      | —               | non couverte        | —                       |

## Cas d'utilisation (SRS chap. 8)

| ID         | Libelle                                           | Palier | Articles de loi | Etat         | Tests |
| ---------- | ------------------------------------------------- | ------ | --------------- | ------------ | ----- |
| `UC-M1-01` | Configurer la connexion à KoboToolbox             | —      | —               | non couverte | —     |
| `UC-M1-02` | Synchroniser les soumissions depuis KoboToolbox   | —      | —               | non couverte | —     |
| `UC-M1-03` | Importer manuellement un fichier CSV/Excel        | —      | —               | non couverte | —     |
| `UC-M1-04` | Consulter le journal d'ingestion                  | —      | —               | non couverte | —     |
| `UC-M2-01` | Consulter la carte des producteurs (public)       | —      | —               | non couverte | —     |
| `UC-M2-02` | Filtrer dynamiquement la carte                    | —      | —               | non couverte | —     |
| `UC-M2-03` | Activer / désactiver une couche cartographique    | —      | —               | non couverte | —     |
| `UC-M2-04` | Rechercher un producteur par nom, sigle ou code   | —      | —               | non couverte | —     |
| `UC-M2-05` | Exporter la vue cartographique                    | —      | —               | non couverte | —     |
| `UC-M3-01` | Consulter le tableau de bord opérationnel         | —      | —               | non couverte | —     |
| `UC-M3-02` | Consulter le tableau de bord stratégique          | —      | —               | non couverte | —     |
| `UC-M3-03` | Exporter le tableau de bord                       | —      | —               | non couverte | —     |
| `UC-M3-04` | Personnaliser son tableau de bord                 | —      | —               | non couverte | —     |
| `UC-M4-01` | Consulter la file d'attente de validation         | —      | —               | non couverte | —     |
| `UC-M4-02` | Valider une soumission                            | —      | —               | non couverte | —     |
| `UC-M4-03` | Rejeter une soumission                            | —      | —               | non couverte | —     |
| `UC-M4-04` | Fusionner deux fiches (doublons)                  | —      | —               | non couverte | —     |
| `UC-M4-05` | Modifier une fiche validée                        | —      | —               | non couverte | —     |
| `UC-M4-06` | Consulter une fiche détaillée                     | —      | —               | non couverte | —     |
| `UC-M4-07` | Consulter l'historique des modifications          | —      | —               | non couverte | —     |
| `UC-M4-08` | Restaurer une version antérieure                  | —      | —               | non couverte | —     |
| `UC-M4-09` | Archivage logique d'une fiche                     | —      | —               | non couverte | —     |
| `UC-M5-01` | Authentification d'un point focal archives        | —      | —               | non couverte | —     |
| `UC-M5-02` | Consulter la fiche de sa structure                | —      | —               | non couverte | —     |
| `UC-M5-03` | Soumettre une proposition de modification         | —      | —               | non couverte | —     |
| `UC-M5-04` | Examiner et valider/refuser une proposition (ANC) | —      | —               | non couverte | —     |
| `UC-M5-05` | Gérer les comptes points focaux                   | —      | —               | non couverte | —     |
| `UC-M6-01` | Créer un compte utilisateur                       | —      | —               | non couverte | —     |
| `UC-M6-02` | Désactiver un compte utilisateur                  | —      | —               | non couverte | —     |
| `UC-M6-03` | Consulter les journaux d'audit                    | —      | —               | non couverte | —     |
| `UC-M6-04` | Configurer le système (paramètres techniques)     | —      | —               | non couverte | —     |
| `UC-M6-05` | Restauration depuis une sauvegarde                | —      | —               | non couverte | —     |
| `UC-M7-01` | Consommer l'API publique (anonyme)                | —      | —               | non couverte | —     |
| `UC-M7-02` | Consommer l'API chercheur (authentifié)           | —      | —               | non couverte | —     |
| `UC-M7-03` | Exporter un dump volumétrique                     | —      | —               | non couverte | —     |
| `UC-M7-04` | Consulter la documentation OpenAPI                | —      | —               | non couverte | —     |
