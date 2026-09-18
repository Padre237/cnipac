# ADR-034 — Interdire les donnees reelles hors production et fournir des jeux synthetiques

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : RSSI + administrateur metier ANC
- **Perimetre** : technique et **metier**
- **Exigences concernees** : **NFR-C4-01**, **NFR-C9-02**, NFR-C4-04, SDD §8.1, art. 13 et 22 Loi 2024/001

## Contexte

Le SDD §8.1 pose le principe : « aucune donnee reelle ne transite par DEV ou PREPROD ».
Il prevoit pour PREPROD un « jeu de donnees realiste **anonymise** de 200 a 1 000
producteurs ». Le principe est enonce ; sa mise en oeuvre n'est decrite nulle part.

Le mode de defaillance est connu et frequent : pour reproduire un defaut, un developpeur
restaure un dump de production en PREPROD. Les donnees nominatives des points focaux
archives — noms, telephones, courriels, proteges par NFR-C4-01 — se retrouvent alors dans un
environnement moins durci, potentiellement sur un poste de travail, voire dans une sauvegarde
de poste heberge hors du territoire, ce qui violerait NFR-C9-02.

S'y ajoute une contrainte metier propre a CNIPAC : les tests ont besoin de donnees
**geospatialement credibles**. Des coordonnees aleatoires ne testent ni le clustering
PostGIS, ni le controle d'enveloppe territoriale de RG-M2-03, ni la repartition par region.

## Decision

**1. Interdiction absolue**, techniquement appliquee. `scripts/deploy.sh` refuse toute
restauration d'une sauvegarde issue de PROD vers un environnement non-PROD : les archives
pgBackRest portent une etiquette d'environnement verifiee avant restauration.

**2. Trois jeux de donnees synthetiques**, versionnes dans `infra/postgres/seed/` :

| Jeu       | Volume             | Usage                                                     | Source                                                                |
| --------- | ------------------ | --------------------------------------------------------- | --------------------------------------------------------------------- |
| `dev`     | 50 producteurs     | Developpement local, tests d'integration                  | Genere, coordonnees reelles des ministeres (donnees publiques du TDR) |
| `preprod` | 1 000 producteurs  | Recette, demonstrations, ateliers A1/A2                   | Genere ; 200 reels publics + 800 synthetiques                         |
| `charge`  | 15 000 producteurs | Tests k6 (NFR-C1-04) et extensibilite (NFR-C6-06, 50 000) | Entierement genere                                                    |

**3. Le socle public est legitime.** Les coordonnees des ministeres, conseils regionaux et
etablissements publics figurent dans le TDR (§7) et dans `infra/postgres/seed/01_admin_points.sql`.
Ce sont des donnees publiques d'organismes publics — leur usage en PREPROD ne pose aucune
difficulte. **Aucune donnee nominative de personne physique n'y figure ni ne doit y figurer.**

**4. Les donnees nominatives sont integralement synthetiques.** Noms, telephones et courriels
des points focaux sont generes (`prenom.nom@test.cnipac.cm`, numeros dans une plage reservee
non attribuable). Aucune personne reelle n'est representee.

**5. Le generateur respecte les regles de gestion**, ce qui fait du jeu de donnees un
instrument de test et non un simple remplissage :

- coordonnees comprises dans l'enveloppe du Cameroun — teste RG-M2-03 ;
- 5 % de producteurs **sans** coordonnees valides — teste la branche d'exclusion de RG-M2-03 ;
- repartition realiste sur les 9 reseaux archivistiques et les 10 regions ;
- doublons potentiels deliberes sur le triplet (sigle, ministere, commune) — teste RG-M1-03
  et le parcours E2E P-B du SDD §25.9.2 ;
- distribution des statuts couvrant l'automate de RG-M1-05, quarantaine comprise ;
- indice de maturite archivistique distribue sur toute l'echelle — teste RG-M3-01 ;
- au moins une region comptant **moins de 5 producteurs** — teste le seuil d'agregation de
  RG-M3-02, qui interdit toute statistique sur un echantillon inferieur a 5.

Le generateur est **deterministe** : la meme graine produit le meme jeu, ce qui rend les
tests reproductibles.

**6. Exception encadree.** L'investigation d'un incident de production exigeant des donnees
reelles se fait **sur l'environnement de production**, par un administrateur habilite, avec
journalisation d'audit (NFR-C4-04 pour toute extraction de plus de 100 fiches). Jamais par
copie vers un autre environnement.

## Consequences

**Positives** — NFR-C9-02 et NFR-C4-01 sont protegees par un dispositif technique, non par
une consigne. Le jeu de donnees devient un instrument de test des regles de gestion. Les
demonstrations des ateliers A1 et A2 n'exposent aucune donnee nominative reelle devant un
auditoire de 30 a 100 personnes — point souvent neglige et pourtant reel.

**Negatives / couts** — Le generateur est a ecrire et a maintenir (estime : 2 a 3 jours au
Sprint 2). Certains defauts ne se reproduisent que sur des donnees reelles ; ils
s'investiguent alors en production, ce qui est plus contraignant mais correct.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                       | Raison du rejet                                                                                                                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Dump de PROD anonymise a la volee | L'anonymisation par script laisse regulierement des residus (commentaires libres, pieces jointes, journaux d'audit). Risque non nul sur donnees protegees par la Loi 2024/001. |
| Donnees entierement aleatoires    | Ne testent aucune regle de gestion. Rendent les demonstrations peu credibles devant les ANC.                                                                                   |
| Aucun jeu de donnees, base vide   | Rend impossibles les tests de charge (NFR-C1-04) et les ateliers de validation.                                                                                                |

## Mise en oeuvre

`scripts/generer-jeu-de-donnees.mjs`, `infra/postgres/seed/`,
`docs/regles-metier/jeux-de-donnees.md`, `scripts/deploy.sh` (verification d'etiquette),
job `verification-donnees-test` de `.github/workflows/security.yml`.
