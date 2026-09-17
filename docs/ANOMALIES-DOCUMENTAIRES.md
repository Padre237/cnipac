# Anomalies relevées dans les documents de référence

**Destinataire** : Comité de Pilotage, équipe métier ANC
**Émetteur** : Équipe technique CENADI
**Date** : 17 septembre 2026

Le schéma de base de données applique le SRS V2.0, le SDD V4.0 et le formulaire
KoboToolbox **à la lettre**. Ce faisant, quelques points appellent un arbitrage :
des coquilles reproduites fidèlement, et des divergences entre documents.

Aucun n'a été corrigé de ma propre initiative. Ce document existe pour qu'ils
soient tranchés, et non découverts en production.

---

## A-01 — `accepteee` : coquille dans un type ENUM

| | |
|---|---|
| **Source** | SDD §12.2, type `statut_proposition_enum` |
| **Constat** | La valeur s'écrit `accepteee`, avec **trois** « e » |
| **Reproduit** | Oui, à l'identique, dans `01_types_enum.sql` |
| **Criticité** | Faible techniquement, élevée en maintenance |

Une valeur d'ENUM est un contrat : toute requête applicative, tout export et
toute documentation devront employer cette graphie pendant toute la vie du
système. La corriger plus tard supposera une migration et une reprise du code.

**Recommandation** : corriger en `acceptee` **avant** la première mise en
production. Le coût est nul aujourd'hui, réel dans six mois.

---

## A-02 — `ctd` : deux notions distinctes sous un même code

| | |
|---|---|
| **Sources** | Formulaire Kobo I.2 (`choices.type_organisation`) et SRS §12.10 |
| **Criticité** | Moyenne — affecte la qualité du référentiel |

Le formulaire propose le code `ctd` avec le libellé « **Service déconcentré**
(CTD) ». Or le SRS §12.10 distingue explicitement deux types d'entité :

- **CTD** — collectivité territoriale décentralisée (région, commune) ;
- **service déconcentré** — représentation locale de l'État (délégation
  régionale d'un ministère).

Ce ne sont pas les mêmes structures, et elles ne relèvent pas de la même
tutelle. Un agent de collecte lisant « Service déconcentré (CTD) » cochera la
même case dans les deux cas : **les deux populations deviendront indiscernables
dans le référentiel national.**

La fonction `mapper_type_organisation()` fait aujourd'hui correspondre `ctd` au
type `ctd`, en privilégiant le code sur le libellé. Le choix est explicite et
documenté, mais il ne résout pas l'ambiguïté de saisie.

**Recommandation** : scinder la question en deux choix distincts dans le
formulaire, avant le déploiement de la collecte. Après, les données collectées
ne seront pas rattrapables sans re-enquête.

---

## A-03 — Enveloppe géographique : 8.4 ou 8.5 ?

| | |
|---|---|
| **Sources** | SRS §12.3 (II.2) et SDD §12.3 concordent sur **8.5** |
| **Retenu** | 8.5 |

La longitude minimale retenue est **8.5**, conformément aux deux documents.
Signalé ici car la limite occidentale réelle du Cameroun est proche de 8,49° E
(pointe de la péninsule de Bakassi). Un producteur situé à l'extrême ouest
pourrait être rejeté par la contrainte `chk_producteur_geom_in_cameroun`.

**Recommandation** : vérifier auprès de l'INC. Si l'enveloppe doit être élargie,
le faire avant la collecte — et dans les deux documents simultanément.

---

## A-04 — Communes : ~360 annoncées, 290 dans le formulaire

| | |
|---|---|
| **Sources** | SRS §12.10 annonce « ~360 communes » ; le XLSForm en recense **290** |
| **Retenu** | Les 290 du formulaire |

C'est le formulaire qui fait foi pour l'ingestion : un arrondissement absent de
sa liste ne peut pas être soumis depuis le terrain. Charger 360 entrées dont 70
seraient inatteignables donnerait une fausse impression de complétude.

**Recommandation** : faire arbitrer par les ANC et le BUCREP. Si des communes
manquent, les ajouter **au formulaire**, puis régénérer le référentiel par
`scripts/generer-seed-depuis-xlsform.py`.

---

## A-05 — Critères de maturité absents du formulaire

| | |
|---|---|
| **Sources** | RG-M3-01 (annexe F) et formulaire Kobo section VI |
| **Criticité** | Moyenne — affecte un indicateur national |

La formule de l'indice de maturité repose sur six critères. Le formulaire n'en
collecte que trois directement :

| Critère (pondération) | Collecté par le formulaire ? |
|---|---|
| Service d'archives dédié (25 %) | **Non** |
| Personnel formé (15 %) | Indirectement — présence d'archivistes en III.2 |
| Locaux adaptés (20 %) | Indirectement — type de bâtiment en III.4 |
| Plan de classement (20 %) | Oui — `outils_gestion` |
| Calendrier de conservation (10 %) | Oui — `outils_gestion` |
| Instruments de recherche (10 %) | Oui — `instruments_recherche` |

Le schéma prévoit trois colonnes `service_archives_dedie`, `personnel_forme` et
`locaux_adaptes` dans `maturite_archivistique`, renseignées par l'archiviste
lors de la validation. La fonction `calculer_score_maturite()` retombe sur les
déductions indirectes lorsqu'elles ne le sont pas.

**Conséquence** : sans saisie par l'archiviste, le critère « service d'archives
dédié » — le plus lourd de la formule — vaut toujours zéro. **L'indice national
serait sous-estimé de 25 points.**

**Recommandation** : ajouter une question au formulaire (« La structure
dispose-t-elle d'un service d'archives constitué ? »), ou inscrire cette saisie
au protocole de validation des archivistes. La première option est préférable :
l'agent de terrain est mieux placé que l'archiviste pour l'observer.

---

## A-06 — Sections III à VII : pas de DDL dans le SDD

| | |
|---|---|
| **Source** | SDD §12 : « le DDL exhaustif est reporté à l'**Annexe A** » |
| **Constat** | L'annexe A n'a pas été fournie avec le document |

Le SDD détaille dans son corps les tables `producteur`, `version_fiche`,
`soumission_kobo`, `utilisateur`, `evenement_audit` et les jonctions RBAC. Les
sections III à VII du dictionnaire fonctionnel — centre de préarchivage,
patrimoine, risques, maturité, logistique — n'ont pas de DDL publié.

Ces tables ont donc été **conçues** à partir du formulaire Kobo et du SRS §12.4
à §12.8, et non transcrites. Elles constituent une proposition d'Annexe A.

**Recommandation** : faire valider `05_sections_metier.sql` par l'architecte
CENADI, et l'annexer au SDD. C'est la seule partie du schéma qui ne soit pas
adossée à un DDL existant.
