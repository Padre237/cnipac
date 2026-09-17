# Runbooks d'exploitation CNIPAC

Un runbook se lit **pendant** l'incident, pas avant. Il est donc écrit pour être
exécuté sous stress, la nuit, par quelqu'un qui n'a pas écrit le système :
commandes exactes, critères de décision explicites, pas de prose.

| Réf | Titre | Quand |
|---|---|---|
| [RB-01](RB-01-configuration-depot.md) | Configuration initiale du dépôt et des environnements | Sprint 1 |
| [RB-02](RB-02-deploiement-production.md) | Déploiement en production | À chaque release |
| [RB-03](RB-03-rollback.md) | Retour arrière | Incident après déploiement |
| [RB-04](RB-04-restauration.md) | Restauration de la base | Perte de données, corruption |
| [RB-05](RB-05-maintenance-tier-donnees.md) | Maintenance du tier données | Fenêtre planifiée |
| [RB-06](RB-06-astreinte-et-alertes.md) | Astreinte et traitement des alertes | Alerte Prometheus |
| [RB-07](RB-07-rotation-des-cles.md) | Rotation des secrets et des clés | Tous les 90/180 jours |
| [RB-08](RB-08-traitement-vulnerabilites.md) | Traitement d'une vulnérabilité | Alerte SCA, DAST ou pentest |
| [RB-09](RB-09-rupture-chaine-audit.md) | Rupture de la chaîne du journal d'audit | Alerte de criticité maximale |

## Règle de rédaction

Tout runbook référencé par une alerte Prometheus (champ `runbook` de
l'annotation) **doit exister**. Une alerte qui renvoie vers un runbook
inexistant est pire qu'une alerte sans runbook : elle fait perdre du temps au
moment où il en manque le plus.

## Exercices

| Procédure | Fréquence d'exercice | Vérification |
|---|---|---|
| RB-03 Rollback | À chaque jalon (P1, P2, P3) | Exercice en PREPROD |
| RB-04 Restauration | **Hebdomadaire, automatisée** | `.github/workflows/backup-restore-drill.yml` |
| RB-07 Rotation des clés | Une fois avant la mise en production P3 | Exercice documenté |

Une procédure jamais exercée ne fonctionne pas. C'est la raison pour laquelle
l'exercice de restauration — que le SDD prévoyait trimestriel et manuel — est
automatisé et hebdomadaire (ADR-021).
