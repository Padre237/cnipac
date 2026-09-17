# ADR-014 — Heberger le code sur GitHub prive institutionnel, executer la CI sur des runners self-hosted CENADI

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + RSSI
- **Perimetre** : technique
- **Exigences concernees** : NFR-C6-02, NFR-C9-01, NFR-C9-02, NFR-C9-03, AC-P1-09

## Contexte

Le SRS §2.6.3 laisse le choix ouvert : « Git, heberge sur instance GitLab interne CENADI
**ou** GitHub prive ». Le SDD §26.4 tranche implicitement en ecrivant un workflow GitHub
Actions. Le SDD §4.4 note d'ailleurs que GitHub Actions est le seul composant
**proprietaire** de toute la stack.

Deux questions distinctes doivent etre separees, ce que les documents ne font pas :

1. **Ou vit le code source ?** — question de propriete intellectuelle (NFR-C9-04) ;
2. **Ou s'execute la CI, et que voit-elle ?** — question de souverainete des donnees
   (NFR-C9-02) et d'acces reseau au datacenter.

NFR-C9-02 interdit la sortie du territoire des **donnees nominatives et des journaux
d'audit**. Il n'interdit pas la sortie du code source. Un depot prive GitHub ne viole donc
pas C9-02. En revanche, un runner heberge par GitHub (infrastructure situee aux Etats-Unis)
qui executerait des tests d'integration sur un jeu de donnees reel violerait C9-02 — et,
surtout, ne peut techniquement pas atteindre le datacenter CENADI, qui n'expose aucun port
entrant hors 443.

## Decision

1. **Code source** : depot **prive** sous l'organisation GitHub institutionnelle
   `cenadi-cm`. Le depot porte la mention de propriete NFR-C9-04 (fichier `LICENSE`).
2. **Runners** : deux categories, avec une regle d'affectation stricte.

| Categorie | Ou | Ce qui y tourne | Donnees manipulees |
|---|---|---|---|
| `ubuntu-latest` (heberge GitHub) | Cloud GitHub | lint, typecheck, tests unitaires, tests d'integration sur base ephemere, build, SCA, SBOM | **Exclusivement synthetiques** (ADR-034) |
| `[self-hosted, cnipac, cenadi]` | Datacenter CENADI | deploiement PREPROD et PROD, migrations, tests de charge k6, DAST ZAP, exercices de restauration | Donnees reelles autorisees |

**Regle d'affectation, opposable en revue** : tout job qui touche une donnee reelle, un
secret de production ou un hote CENADI s'execute sur un runner self-hosted. Aucune
exception. Le workflow `security.yml` contient un controle automatique qui echoue si un
job referencant un environnement `preprod` ou `production` declare un runner heberge.
3. **Sortie de dependance** : la totalite de la logique CI est ecrite dans des **scripts
   Node et shell** places dans `scripts/`, appeles par des workflows fins. Une migration
   vers GitLab CI ou Forgejo Actions consiste alors a reecrire les fichiers YAML
   d'orchestration, pas la logique. Cout de sortie borne a environ 3 jours.

## Consequences

**Positives**

- Repond a AC-P1-09 (« code versionne sur GitHub institutionnel avec pipeline CI/CD »).
- Aucun port entrant a ouvrir sur le datacenter : le runner self-hosted etablit une
  connexion **sortante** vers GitHub. C'est l'argument decisif face au RSSI.
- Les minutes de calcul lourdes (lint, tests) sont supportees par GitHub, pas par le
  materiel CENADI deja dimensionne au plus juste (§8.3).

**Negatives / couts**

- Dependance a un service proprietaire etranger pour l'orchestration, en tension avec
  l'esprit de NFR-C9-03. Assumee et bornee par la strategie de sortie ci-dessus.
- Le runner self-hosted est une machine a durcir : utilisateur dedie non privilegie,
  workspace ephemere nettoye apres chaque job, aucun secret persistant sur disque.
  Procedure dans `infra/host/runner-hardening.md`.
- Un depot prive consomme des minutes GitHub Actions facturees au-dela du quota.

**Irreversibilite** — Moyenne. Migration vers GitLab CI estimee a 3 jours grace a
l'externalisation de la logique dans `scripts/`.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| GitLab CE auto-heberge au CENADI | Le plus souverain, mais ajoute un service critique a exploiter (sauvegardes, montees de version, haute disponibilite) a une equipe de 4 personnes qui doit deja livrer P1 en 22 semaines. A reevaluer en Phase 2 post-pilote. |
| GitHub avec runners heberges uniquement | Techniquement impossible : aucun acces entrant au datacenter CENADI. |
| Depot public des le pilote | La publication du code releve d'une decision COPIL non acquise. Un depot public exposerait la surface d'attaque du systeme avant le premier pentest. |

## Mise en oeuvre

`.github/workflows/*.yml`, `scripts/`, `infra/host/runner-hardening.md`,
controle automatique dans `.github/workflows/security.yml` (job `regle-affectation-runners`).
