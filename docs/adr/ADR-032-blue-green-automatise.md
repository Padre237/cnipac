# ADR-032 — Automatiser le Blue-Green en conservant une approbation humaine en production

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + exploitation CENADI
- **Perimetre** : technique
- **Exigences concernees** : NFR-C2-01, NFR-C2-02, **NFR-C2-03 (RTO <= 4 h)**, SDD §26.5 a §26.8

## Contexte

Le SDD §26 pose une position explicite : « le perimetre traite se limite au deploiement
(et non a une approche DevOps complete) : la mise en production manuelle assistee par CI/CD
leger reste la cible en P1 et P2 ». La procedure §26.5 decrit huit etapes manuelles, dont
`docker compose pull`, `prisma migrate deploy` et des tests de fumee.

Deux constats s'opposent a une execution purement manuelle :

1. **Le SDD §26.6 decrit lui-meme un Blue-Green** avec basculement en quelques secondes et
   rollback equivalent, applicable « en P2 et au-dela pour toutes les releases majeures ».
   Un basculement Blue-Green execute a la main, sous stress, la nuit, est precisement le
   scenario ou l'erreur survient.
2. **NFR-C2-03 exige un RTO <= 4 heures.** Une procedure manuelle de huit etapes, executee
   par un administrateur d'astreinte a 2 h du matin, est le facteur de risque principal de
   cette exigence.

Il faut distinguer deux choses que le SDD confond : **qui decide de deployer** (question de
gouvernance) et **qui execute les huit etapes** (question d'outillage).

## Decision

**La decision reste humaine. L'execution est automatisee.**

| Environnement | Declencheur                     | Approbation                                            | Strategie                                         |
| ------------- | ------------------------------- | ------------------------------------------------------ | ------------------------------------------------- |
| **DEV**       | push sur `main`                 | aucune                                                 | remplacement direct                               |
| **PREPROD**   | push sur `main`, apres CI verte | aucune                                                 | Blue-Green automatique                            |
| **PROD**      | tag `vX.Y.Z` signe              | **2 approbateurs** via GitHub Environment `production` | Blue-Green automatique + tests de fumee + bascule |

La porte d'approbation GitHub Environment materialise exactement l'exigence du SDD §26.4
(« approbation explicite GitHub Actions ») et de §26.5 (« a charge d'un administrateur CENADI
autorise »). Un humain autorise decide ; le script execute.

**Sequence automatisee en PROD** :

1. Verification de la signature cosign de l'image (ADR-024) — sinon arret ;
2. Sauvegarde prealable pgBackRest complete et **verifiee** — sinon arret (SDD §26.5 etape 2) ;
3. Application des migrations Prisma, avec le garde-fou d'ADR-027 deja passe en PR ;
4. Demarrage de la pile Green en parallele de Blue, sans trafic ;
5. Tests de fumee sur Green : `/health`, authentification administrateur, carte publique,
   une requete API authentifiee, un point d'entree M3 (SDD §26.5 etape 6) ;
6. Bascule Nginx vers Green ;
7. Observation pendant 10 minutes : taux d'erreur 5xx, latence P95, saturation. Tout
   depassement de seuil declenche **une bascule arriere automatique** vers Blue ;
8. Blue conserve demarre pendant 24 heures, puis arrete — le rollback reste instantane
   pendant ce delai ;
9. Notification a l'equipe et journalisation du deploiement.

**Rollback** : les trois mecanismes du SDD §26.8 sont scriptes dans `scripts/rollback.sh` —
bascule arriere Nginx (secondes), redeploiement d'une image anterieure (minutes),
restauration pgBackRest avec PITR (dizaines de minutes, cf. ADR-021).

**Migrations retrocompatibles obligatoires.** Le Blue-Green suppose que Blue et Green
partagent la meme base. Toute migration doit donc etre compatible avec les deux versions
applicatives : on ajoute avant de retirer, on ne renomme jamais en une seule etape. La regle
est explicitee dans `docs/conventions/MIGRATIONS.md` et rappelee par le garde-fou d'ADR-027.

## Consequences

**Positives** — La procedure du SDD §26.5 est executee a l'identique a chaque fois, sans
etape oubliee. Le RTO s'ameliore nettement : le rollback est une commande, pas une
restauration. La gouvernance est preservee : personne ne deploie en production sans
approbation.

**Negatives / couts** — Double empreinte memoire pendant la fenetre de bascule ; l'hote H1
(8 Go, SDD §8.3) doit pouvoir heberger deux instances du backend simultanement, soit environ
1,5 Go. Verifie et documente. La contrainte de retrocompatibilite des migrations est une
discipline reelle a acquerir.

**Irreversibilite** — Nulle : `scripts/deploy.sh --mode=manuel` reproduit exactement la
procedure du SDD §26.5, etape par etape, en mode interactif.

## Alternatives ecartees

| Alternative                                   | Raison du rejet                                                                                     |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Procedure 100 % manuelle, lettre du SDD §26.5 | Variabilite humaine sur huit etapes critiques, la nuit. Facteur de risque principal pour NFR-C2-03. |
| Deploiement continu sans approbation          | Contraire au SDD §26.4 et a la gouvernance attendue d'un systeme d'Etat.                            |
| Deploiement Canary systematique               | Le SDD §26.7 le reserve aux cas critiques. Complexite injustifiee pour une release ordinaire.       |

## Mise en oeuvre

`scripts/deploy.sh`, `scripts/rollback.sh`, `scripts/tests-de-fumee.sh`,
`.github/workflows/cd-preprod.yml`, `.github/workflows/cd-prod.yml`,
`infra/nginx/blue-green/`, `docs/runbooks/RB-02-deploiement-production.md`,
`docs/runbooks/RB-03-rollback.md`, `docs/conventions/MIGRATIONS.md`.
