# Jeux de données de test

**ADR** : [034](../adr/ADR-034-donnees-de-test.md) · **Exigences** : NFR-C4-01, NFR-C9-02, SDD §8.1

## La règle

**Aucune donnée réelle ne transite par DEV ou PREPROD.** Le principe est posé
par le SDD §8.1 ; ce document en décrit la mise en œuvre.

Le mode de défaillance à prévenir est banal : pour reproduire un défaut, un
développeur restaure un dump de production en PREPROD. Les données nominatives
des points focaux — noms, téléphones, courriels, protégés par NFR-C4-01 — se
retrouvent alors dans un environnement moins durci, potentiellement sur un poste
de travail, voire dans une sauvegarde de poste hébergée hors du territoire, ce
qui violerait NFR-C9-02.

`scripts/deploy.sh` refuse techniquement la restauration d'une archive étiquetée
PROD vers un environnement non-PROD.

## Les trois jeux

| Jeu | Volume | Usage |
|---|---|---|
| `dev` | 50 producteurs | Développement local, tests d'intégration |
| `preprod` | 1 000 producteurs | Recette, ateliers A1 et A2, démonstrations |
| `charge` | 15 000 producteurs | Tests k6 (NFR-C1-04), extensibilité (NFR-C6-06) |

## Ce qui est légitime, ce qui ne l'est pas

**Légitime** : les coordonnées des ministères, conseils régionaux et
établissements publics. Ce sont des données publiques d'organismes publics,
figurant au TDR §7 et dans `infra/postgres/seed/01_admin_points.sql`. Elles
rendent les démonstrations crédibles devant les ANC.

**Interdit** : toute donnée nominative de personne physique. Les correspondants
archives, leurs téléphones et leurs courriels sont **intégralement synthétiques**.

## Plages réservées

| Donnée | Plage de test | Vérification |
|---|---|---|
| Courriel | `prenom.nom@test.cnipac.cm` | `gate-donnees-test.mjs` |
| Téléphone | `+237 699 00 XX XX` | `gate-donnees-test.mjs` |
| Nom de personne | Généré, jamais repris d'une source réelle | revue |

## Le générateur teste les règles de gestion

Un jeu de données aléatoire ne teste rien. Le générateur doit produire, par
construction, les cas limites suivants — c'est ce qui en fait un instrument de
test plutôt qu'un remplissage.

| Caractéristique imposée | Règle testée |
|---|---|
| Coordonnées dans l'enveloppe du Cameroun | RG-M2-03, branche nominale |
| **5 % de fiches sans coordonnées valides** | RG-M2-03, branche d'exclusion |
| Répartition réaliste sur les 9 réseaux et 10 régions | RG-M2-04 |
| **Doublons délibérés** sur le triplet (sigle, ministère, commune) | RG-M1-03, parcours E2E P-B du SDD §25.9.2 |
| Tous les statuts de l'automate, quarantaine comprise | RG-M1-05 |
| Indice de maturité réparti sur toute l'échelle | RG-M3-01 |
| **Au moins une région à moins de 5 producteurs** | RG-M3-02, seuil d'agrégation |
| Fiches avec et sans pièces jointes | FR-M4-13 |
| Comptes de test pour les 8 rôles RBAC | AC-P1-06 |

## Déterminisme

Le générateur est déterministe : une même graine produit un même jeu. Un test
qui échoue est donc reproductible, et une démonstration donne toujours le même
résultat — ce qui compte devant un auditoire de 80 à 100 personnes (atelier A3).

```bash
pnpm --filter @cnipac/backend exec prisma db seed -- --jeu=preprod --graine=2026
```

## Et pour investiguer un incident de production ?

Sur l'environnement de production, par un administrateur habilité, avec
journalisation d'audit — et notification à l'administrateur métier au-delà de
100 fiches (NFR-C4-04). Jamais par copie vers un autre environnement.
