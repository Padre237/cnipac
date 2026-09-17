# Politique de sécurité — CNIPAC

## Signaler une vulnérabilité

**Ne pas ouvrir de ticket public.** Écrire à `securite@cenadi.cm` (RSSI du
CENADI), en précisant : la nature de la faille, les étapes de reproduction,
l'impact estimé, et vos coordonnées.

Accusé de réception sous **48 heures ouvrées**. Évaluation initiale sous
**5 jours ouvrés**.

## Délais de correction

| Criticité (CVSS) | Correction | Fondement |
|---|---|---|
| Critique (9,0–10,0) | **24 heures** | NFR-C3-04 |
| Haute (7,0–8,9) | **7 jours** | NFR-C3-04 |
| Moyenne (4,0–6,9) | 30 jours | — |
| Basse (0,1–3,9) | Prochaine release planifiée | — |

**NFR-C3-04 : aucune vulnérabilité CVSS ≥ 7 ne doit subsister à la mise en
production.** L'exigence est vérifiée automatiquement et bloque la release.

## Dispositif en place

| Niveau | Outil | Fréquence |
|---|---|---|
| Dépendances | `npm audit`, Trivy, Renovate | Chaque PR + alertes immédiates |
| Code (SAST) | CodeQL `security-extended` | Chaque PR |
| Secrets | gitleaks (diff + historique complet) | Chaque PR + hebdomadaire |
| En-têtes HTTP | Contrôle dédié | Chaque PR, < 60 s |
| Application (DAST) | OWASP ZAP baseline | Chaque déploiement PREPROD |
| Application (DAST complet) | OWASP ZAP full scan | Hebdomadaire + avant chaque jalon |
| **Pentest externe** | Prestataire tiers | Avant P1, P2, P3, puis annuel (NFR-C3-03) |
| Intégrité du journal d'audit | Vérification de chaîne | Continue + exercice hebdomadaire |

## Périmètre

Le système traite des données relatives au patrimoine archivistique national.
Les données nominatives des correspondants archives sont protégées par
NFR-C4-01 et par la Loi n° 2024/001 : elles ne sont jamais exposées
publiquement, ni dans la carte, ni dans l'API non authentifiée.

Une atteinte à l'intégrité du **journal d'audit** constitue l'incident le plus
grave envisageable : l'article 32 de la loi en impose l'immuabilité. Procédure
dédiée : [RB-09](docs/runbooks/RB-09-rupture-chaine-audit.md).

## Ce que nous demandons

Ne pas exploiter une faille au-delà de ce qui est nécessaire pour la démontrer.
Ne pas accéder, modifier ou exfiltrer de données. Ne pas divulguer publiquement
avant correction et accord du CENADI.
