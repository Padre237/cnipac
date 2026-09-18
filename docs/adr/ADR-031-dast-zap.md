# ADR-031 — Executer le DAST OWASP ZAP hors du chemin critique de pull request

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + RSSI
- **Perimetre** : technique
- **Exigences concernees** : **NFR-C3-04**, NFR-C3-07, AC-P1-10, SDD §25.6, SRS §14.7

## Contexte

Le SRS et le SDD exigent un scan OWASP ZAP (AC-P1-10 : « aucune vulnerabilite critique ou
haute identifiee par scan automatise OWASP ZAP » ; SDD §25.6 : « execute en CI avant chaque
deploiement PREPROD »).

Contrainte pratique : un scan ZAP complet (`full-scan`) dure de 20 a 45 minutes sur une
application de cette taille. L'inserer dans la CI de pull request porterait le cycle de
retour de 8 minutes a plus de 30. L'equipe contournerait la regle en moins de deux sprints —
c'est le sort de toute porte de qualite trop lente.

Seconde contrainte : un DAST a besoin d'une application **deployee et peuplee**. Sur une pull
request, aucun environnement de ce type n'existe.

## Decision

Trois niveaux, calibres sur leur duree.

| Niveau | Declencheur                                            | Type de scan                                                                                                                                                              | Duree       | Effet                                                 |
| ------ | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ----------------------------------------------------- |
| **1**  | Chaque PR                                              | Controles statiques d'en-tetes sur l'application demarree en conteneur ephemere : CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy | < 60 s      | **Bloquant**                                          |
| **2**  | Apres chaque deploiement PREPROD                       | `zap-baseline` authentifie, actif passif                                                                                                                                  | 5 a 8 min   | **Bloquant** en HIGH/CRITICAL                         |
| **3**  | Hebdomadaire (dimanche) et avant chaque jalon P1/P2/P3 | `zap-full-scan` avec definition OpenAPI et regles d'authentification                                                                                                      | 30 a 45 min | Rapport au RSSI ; bloquant pour la promotion de jalon |

**Le niveau 1** couvre NFR-C3-07 (durcissement des en-tetes) et s'execute en moins d'une
minute parce qu'il ne teste que la configuration, sans exploration du site.

**Le niveau 3** est la preuve opposable pour AC-P1-10, AC-P2-08 et AC-P3-05.

**Alimentation par l'OpenAPI** : la specification generee par `@nestjs/swagger` (SDD §24.2)
est fournie a ZAP, qui explore alors l'integralite des points d'entree declares au lieu de
les decouvrir par exploration. Couverture nettement superieure pour une duree moindre.

**Scan authentifie** : ZAP dispose de comptes de test pour les 8 roles RBAC, ce qui permet
de detecter les references directes non securisees (IDOR) — classe de vulnerabilite la plus
probable sur un systeme a controle d'acces fin comme CNIPAC.

**Faux positifs** : geres dans `tests/security/zap-rules.tsv`, chaque exclusion portant un
commentaire justificatif et la date de sa derniere revue. Toute exclusion est revue au
trimestre.

**Articulation avec le pentest** : les niveaux 1 a 3 sont automatises. Ils ne remplacent pas
le pentest par un tiers exige par NFR-C3-03 avant chaque mise en production majeure ; ils
evitent que ce pentest — facture au prix fort — ne decouvre des defauts qu'un outil gratuit
aurait detectes.

## Consequences

**Positives** — Retour securite rapide sans ralentir le developpement. AC-P1-10 est couverte
par un artefact automatique et date. Le pentest externe se concentre sur la logique metier.

**Negatives / couts** — Une vulnerabilite detectable uniquement par scan complet peut vivre
jusqu'a une semaine dans `main`. Attenue par le scan systematique au deploiement PREPROD.
ZAP produit des faux positifs qui demandent un arbitrage humain regulier.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                      | Raison du rejet                                                          |
| -------------------------------- | ------------------------------------------------------------------------ |
| Scan complet a chaque PR         | Cycle de retour porte a plus de 30 minutes. La regle serait contournee.  |
| Scan uniquement avant les jalons | Laisse passer des mois entre deux verifications. Contraire a NFR-C3-04.  |
| Outil DAST commercial            | Contraire a NFR-C9-03. ZAP est explicitement nomme par le SRS et le SDD. |

## Mise en oeuvre

`.github/workflows/zap-dast.yml`, `tests/security/zap-rules.tsv`,
`tests/security/zap-auth.context`, `scripts/gate-entetes-securite.mjs`,
`docs/runbooks/RB-08-traitement-vulnerabilites.md`.
