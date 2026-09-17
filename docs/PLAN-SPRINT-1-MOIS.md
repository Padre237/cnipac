# Plan d'exécution — 20 jours ouvrés

**Contrainte** : livrer en un mois. Date de départ : 17 septembre 2026.
**Cible retenue** : **P1 déployé en production**, critères d'acceptation AC-P1-01 à AC-P1-10.

---

## Ce qui rend l'exercice faisable

Ce n'est pas un projet où il faut décider quoi construire. Le SDD V4.0 spécifie
déjà, au niveau de détail de l'implémentation :

| Ce qui est déjà décidé | Où |
|---|---|
| Dictionnaire de données complet, types ENUM, vues matérialisées, fonctions | SDD ch. 12 |
| Architecture interne et algorithmes de chaque module | SDD ch. 13 à 19 |
| Contrats d'API, codes d'erreur, conventions JSON:API | SDD ch. 24 |
| Structure du frontend, routage, gestion d'état | SDD ch. 20 |
| **18 écrans maquettés** + design system | `docs/design/stitch/` |
| Implémentation de la sécurité, avec le code | SDD ch. 23 |
| Socle technique, CI/CD, infrastructure, conventions | **livré** |

**AC-P1-09 et AC-P1-10 sont déjà satisfaits** par le socle. Restent 8 critères sur 10.

La densité de spécification est l'accélérateur principal : le travail est une
transcription dirigée, pas une conception.

---

## Périmètre — ce qu'on livre, ce qu'on ne livre pas

### Livré

| Module | Profondeur | Critères couverts |
|---|---|---|
| **M6** RBAC, audit, authentification | Complet sauf MFA | AC-P1-06, AC-P1-07 |
| **M1** Ingestion, quarantaine, code unique | Complet | AC-P1-01 |
| **M4** Validation, rejet, édition, versions | Noyau | AC-P1-02 |
| **M2** Carte, clusters, filtres, fiche | Complet P1 | AC-P1-03, AC-P1-04, AC-P1-08 |
| **M3** Tableau de bord national | 4 indicateurs | AC-P1-05 |

### Hors périmètre — déjà exclu de P1 par le SRS §14.3

M5 crowdsourcing · M7 API publique et open data · MFA · interface anglaise ·
PWA hors ligne · carte choroplèthe · fusion de doublons · export EAC-CPF.

### Coupes supplémentaires, assumées pour tenir les 20 jours

| Coupe | Justification | Conséquence |
|---|---|---|
| **Déploiement Blue-Green non activé** | Le SDD §26.6 le prévoit « en P2 et au-delà ». Le mécanisme est livré, il n'est pas mis en service ce mois-ci. | Déploiement direct, rollback par image antérieure. Gain : ~2 jours. |
| **Grafana repoussé** | Aucun critère AC-P1 ne l'exige. Prometheus et les règles SLO sont déployés. | Supervision par requêtes Prometheus, tableaux de bord en semaine 5. |
| **Matrice E2E réduite à Chromium en PR** | La matrice complète tourne sur `main` et avant le jalon. | Retour CI de 35 min à 12 min. NFR-C5-02 reste vérifiée, hors chemin critique. |
| **Seuils de couverture maintenus bas (palier P1)** | 50 % backend, 65 % M1/M4, 70 % M6. | **Ne pas les relever ce mois-ci.** Ils sont le filet qui évite l'effondrement d'un sprint rapide. |

### Ce qui ne se coupe sous aucun prétexte

1. **La chaîne de hachage du journal d'audit.** Non rattrapable : la table n'est pas reconstructible par conception. Article 32 de la loi.
2. **Le modèle RBAC à 8 rôles.** AC-P1-06, et tout le reste en dépend.
3. **La justesse du schéma de données.** Reprendre un schéma après ingestion de données réelles est l'erreur la plus coûteuse disponible.
4. **Le marquage des tests par identifiant d'exigence.** Coût quasi nul, et c'est ce qui produit la preuve de recette.

---

## Le chantier parallèle à lancer aujourd'hui

**AC-P1-03 exige 200 producteurs réels géolocalisés.** Ce n'est pas une tâche de
développement et elle ne doit pas occuper le chemin critique logiciel.

À confier dès aujourd'hui à un agent ANC ou CENADI, hors équipe de développement :

- point de départ : le tableau du TDR §7 (~60 structures avec coordonnées) ;
- compléter depuis les annuaires officiels, l'INS, OpenStreetMap ;
- géocodage des adresses restantes via Nominatim ;
- livrable attendu **fin de semaine 3** : un CSV de 200 lignes conforme au
  dictionnaire de données, prêt à ingérer.

Si ce livrable n'arrive pas, la démonstration se fait sur jeu synthétique et
AC-P1-03 passe en réserve au procès-verbal. Le logiciel, lui, n'est pas bloqué.

---

## Semaine 1 — Socle de données et sécurité

| Jour | Travail | Livrable |
|---|---|---|
| J1 | RB-01 : dépôt, protections, environnements. Docker local si les hôtes CENADI ne sont pas prêts (mitigation SDD §29.7.3). **Escalade infrastructure le jour même.** | Dépôt opérationnel |
| J1–J3 | Schéma Prisma complet (SDD ch. 12) : ENUM, `producteur`, `version_fiche`, `soumission_kobo`, `evenement_audit`, référentiels, tables RBAC | Migrations appliquées |
| J2–J3 | **Journal d'audit à chaînage de hachage** + vérification d'intégrité | `/health/audit-chain` opérationnel |
| J3 | Générateur de jeux synthétiques (ADR-034) | 50 / 1 000 producteurs |
| J4–J5 | M6 : JWT, gardes RBAC, 8 rôles, 5 comptes de test, journalisation des opérations sensibles | **AC-P1-06, AC-P1-07** |

> **Pourquoi l'audit en premier.** C'est la seule pièce du système qui ne se
> corrige pas après coup. `gate-migrations` la protège une fois qu'elle existe —
> encore faut-il qu'elle naisse juste.

## Semaine 2 — Ingestion et cycle de vie

| Jour | Travail | Livrable |
|---|---|---|
| J6–J7 | M1 : **couche d'abstraction d'ingestion** + adaptateur CSV/Excel (FR-M1-03) + adaptateur KoboToolbox si le jeton est disponible. Quarantaine, idempotence, code unique, journal d'ingestion | **AC-P1-01** |
| J8–J9 | M4 : file d'attente de validation, valider, rejeter, éditer, génération de version | **AC-P1-02** |
| J10 | API carte : GeoJSON, filtre par bbox, clustering serveur PostGIS, filtres croisés | Base de AC-P1-03/04 |

> **L'abstraction d'ingestion coûte une journée et supprime une dépendance
> externe bloquante.** Le SRS l'anticipe déjà : HYP-01 prévoit exactement cette
> couche comme plan de repli. Si le jeton Kobo arrive, l'adaptateur se branche ;
> s'il n'arrive pas, l'import CSV satisfait la démonstration.

## Semaine 3 — Interface

| Jour | Travail | Livrable |
|---|---|---|
| J11–J12 | Coque SPA, connexion, layout administrateur, design system transposé depuis `docs/design/stitch/` | Navigation complète |
| J13–J14 | Carte Leaflet : marqueurs, clusters, filtres réseau/région/ministère, fiche synthétique au clic | **AC-P1-03, AC-P1-04** |
| J15 | Console de quarantaine et écran de validation (IHM-ADM-01, IHM-ADM-02) | Parcours complet de bout en bout |

## Semaine 4 — Production et recette

| Jour | Travail | Livrable |
|---|---|---|
| J16 | M3 : 4 indicateurs nationaux, horodatage de fraîcheur (RG-M3-03) | **AC-P1-05** |
| J17 | **Déploiement réel** : hôtes CENADI, TLS, secrets, sauvegardes pgBackRest + WAL, Prometheus | Production en service |
| J18 | ZAP complet, k6 léger, audit axe, budget de bundle en 3G, corrections | **AC-P1-08, AC-P1-10** |
| J19 | Chargement des 200 producteurs réels, documentation, rapport de conformité généré | **AC-P1-03** |
| J20 | Répétition de la démonstration, procès-verbal de recette, réserves consignées | Atelier A1 |

---

## Les trois façons dont ce plan échoue

| Risque | Signal d'alerte | Que faire |
|---|---|---|
| **Infrastructure CENADI indisponible en J17** | Pas de FQDN ni d'accès SSH à la fin de la semaine 2 | Escalader dès J1, pas en J15. Repli : hébergement souverain temporaire (CAMTEL, ANTIC — plan B de HYP-04). **Un P1 non déployé n'est pas un P1.** |
| **Dérive sur la carte** | Plus de deux jours sur M2 | La carte est spectaculaire et absorbe le temps sans limite. Limite ferme : J13–J14. Le reste part en P2. |
| **Le schéma est repris en semaine 3** | Une migration destructive est proposée | Ne pas la fusionner. `gate-migrations` la refusera, et il aura raison. Ajouter, ne jamais retirer. |

---

## Décisions à prendre avant J1

| Question | Pourquoi elle bloque |
|---|---|
| Combien de personnes sur le développement ? | À une personne, la semaine 3 (interface) est le point de rupture — envisager d'y concentrer l'aide |
| Le jeton KoboToolbox d'un projet de **test** est-il disponible ? | Détermine l'adaptateur de la semaine 2, et AC-P1-01 |
| Date d'accès aux hôtes H1/H2/H3 ? | Si elle dépasse J15, le déploiement de production est compromis |
| Qui prend le chantier « 200 producteurs réels » ? | À lancer aujourd'hui, pas en semaine 3 |

---

## Les cinq dérogations

Elles restent à valider ([DEROGATIONS.md](DEROGATIONS.md)), mais **ne bloquent
pas le démarrage**. D-04 et D-05 (tier données, archivage WAL) doivent être
tranchées **avant J17**, jour de la mise en production réelle — c'est le moment
où elles deviennent irréversibles.

Les mettre à l'ordre du jour du premier COPIL disponible, avec le présent plan.
Une réunion, deux décisions.
