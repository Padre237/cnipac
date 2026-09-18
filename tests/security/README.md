# Tests de sécurité

**ADR** : [031](../../docs/adr/ADR-031-dast-zap.md)

## Trois niveaux

| Niveau                       | Quand                             | Durée     | Bloquant                            |
| ---------------------------- | --------------------------------- | --------- | ----------------------------------- |
| 1 — En-têtes HTTP            | Chaque PR                         | < 60 s    | Oui                                 |
| 2 — ZAP baseline authentifié | Après chaque déploiement PREPROD  | 5–8 min   | Oui sur HIGH/CRITICAL               |
| 3 — ZAP full scan            | Hebdomadaire + avant chaque jalon | 30–45 min | Bloquant pour la promotion de jalon |

Le niveau 3 alimente l'exploration à partir de la **spécification OpenAPI** :
couverture supérieure à une découverte par crawling, pour une durée moindre.

## Scan authentifié

ZAP dispose de comptes de test pour les 8 rôles RBAC. Cela permet de détecter
les **références directes non sécurisées (IDOR)** — la classe de vulnérabilité
la plus probable sur un système à contrôle d'accès fin comme CNIPAC.

Le fichier `zap-auth.context` (non versionné, généré au déploiement) porte la
configuration d'authentification.

## Ce que l'automatisation ne remplace pas

Les trois niveaux ne se substituent pas au **pentest par un tiers** exigé par
NFR-C3-03 avant chaque mise en production majeure. Ils évitent que ce pentest —
facturé au prix fort — ne découvre des défauts qu'un outil gratuit aurait
détectés.
