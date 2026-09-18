# ADR-017 — Node.js 22 LTS, dans l enveloppe du SDD §4.2

- **Statut** : **REVISE — derogation retiree**, le SDD fait foi
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI
- **Perimetre** : technique
- **Exigences concernees** : NFR-C3-04, NFR-C6-06, critere C-02 du SDD §4.1

> **Cet ADR a ete revise.** La derogation proposant Node 24 est **retiree** sur
> instruction du maitre d'ouvrage : le SDD fait foi.
>
> **Decision retenue : Node.js 22 LTS**, expressement prevu par le SDD §4.2
> (« Node.js LTS — 20.x ou 22.x »). Le choix reste donc **integralement dans
> l'enveloppe du document de conception**, sans derogation.
>
> Node 20 n'est pas retenu au sein de cette enveloppe pour un motif factuel : sa
> fin de support est intervenue en avril 2026. Node 22 est supporte jusqu'en
> avril 2027. Les deux versions etant admises par le SDD, la plus durable est
> choisie — cela releve de l'execution, non d'un ecart de conception.
>
> Mise en oeuvre : `.nvmrc` = 22, `engines.node` = `>=22 <23`, images
> `node:22-alpine`.

---

_Le texte qui suit est conserve a titre de trace de l'analyse initiale._

## Contexte

Le SDD §4.2 retient « Node.js LTS 20.x ou 22.x » et le Dockerfile du §26.2 ecrit
`node:20-alpine`. Ces choix ont ete arretes lors de la redaction du dossier de conception.

Le calendrier de support de Node.js impose de les reexaminer :

| Version | Fin de support | Situation au terme du projet                              |
| ------- | -------------- | --------------------------------------------------------- |
| Node 20 | **avril 2026** | **Deja hors support a la date du present ADR**            |
| Node 22 | avril 2027     | Hors support pendant le contrat de maintenance de 12 mois |
| Node 24 | **avril 2028** | Couvre le pilote et l'integralite de la maintenance       |

Le projet livre P3 en decembre 2026 et s'accompagne d'un plan de maintenance de 12 mois
(TDR §5.6), soit un horizon minimal a decembre 2027.

Deux exigences s'opposent frontalement au maintien de Node 20 :

- **NFR-C3-04** : aucune vulnerabilite CVSS >= 7 a la mise en production. Une version hors
  support ne recoit plus de correctif de securite : l'exigence devient intenable par
  construction des la premiere CVE publiee sur la branche.
- **NFR-C6-06** et le critere C-02 du SDD §4.1 (« version stable majeure, rythme de releases
  regulier ») : demarrer un developpement sur un runtime deja arrive en fin de vie contredit
  l'objectif de longevite decennale enonce en tete du chapitre 4 du SDD.

## Decision

**Node.js 24 LTS** pour le backend, le frontend (outillage de build) et les images Docker.
Version epinglee en trois points, verifies par la CI :

- `.nvmrc` → `24`
- `package.json` → `"engines": { "node": ">=24.0.0 <25" }`
- images Docker → `node:24-alpine`, epinglees par digest (ADR-023)

Le passage a une majeure superieure ne pourra intervenir qu'apres son entree en phase LTS
active, via un ADR dedie.

## Consequences

**Positives** — Le support de securite couvre le pilote et toute la maintenance
contractuelle. NFR-C3-04 redevient tenable. Aucune migration de runtime a prevoir pendant
la duree du marche.

**Negatives / couts** — Ecart documentaire avec le SDD §4.2 et §26.2, a faire valider par
le COPIL. Risque technique reel evalue comme **faible** : NestJS 11 et Vite 5 supportent
Node 24, et aucune dependance de la stack ne plafonne a Node 22.

**Irreversibilite** — Nulle. Un retour a Node 22 se fait en modifiant trois fichiers.

## Alternatives ecartees

| Alternative                          | Raison du rejet                                                                                                                          |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Node 20, conforme a la lettre du SDD | Runtime hors support. Rend NFR-C3-04 intenable. Le respect litteral d'un document ne peut primer sur une exigence de securite chiffree.  |
| Node 22                              | Support jusqu'a avril 2027, insuffisant pour couvrir la maintenance jusqu'a decembre 2027. Imposerait une migration en cours de contrat. |

## Mise en oeuvre

`.nvmrc`, `package.json`, `infra/docker/Dockerfile.backend`, `infra/docker/Dockerfile.frontend`,
job `coherence-versions` de `.github/workflows/ci.yml`.

**Point de validation COPIL** : cette derogation est inscrite a
[../DEROGATIONS.md](../DEROGATIONS.md) et doit etre approuvee avant la cloture du Palier 0.
