# RB-02 — Déploiement en production

**Exigences** : NFR-C2-01, NFR-C2-03 · **ADR** : 032 · **Base** : SDD §26.5 et §26.6

## Avant de commencer

| Condition | Vérification |
|---|---|
| Version déployée en PREPROD et tests de fumée passés | `./scripts/verifier-passage-preprod.sh --version=vX.Y.Z` |
| Tag signé | `git tag -v vX.Y.Z` |
| Images signées cosign | vérifié automatiquement par le workflow |
| Budget d'erreur mensuel < 75 % consommé | tableau de bord Grafana « Conformité SRS » |
| Migrations rétrocompatibles | vérifié en CI (ADR-027) |
| Fenêtre de maintenance annoncée 72 h à l'avance | courriel + bandeau applicatif |
| Deux approbateurs disponibles | environnement GitHub `production` |

**Ne pas déployer** : un vendredi après 15 h, la veille d'un jour férié, ou
pendant les 10 jours précédant un atelier de restitution.

## Déroulement nominal

Le déploiement s'exécute par le workflow `CD PRODUCTION`. L'opérateur le
déclenche, renseigne la version et le motif, puis **deux approbateurs valident**.
La séquence qui suit est automatique.

```
1. Contrôles pré-vol
2. → PORTE D'APPROBATION (2 personnes)
3. Sauvegarde complète vérifiée          ~3 min
4. Migrations Prisma                     ~1 min
5. Démarrage de Green, hors trafic       ~2 min
6. Tests de fumée sur Green              ~1 min
7. Bascule du trafic                     ~15 s
8. Observation 10 min (5xx, P95)
9. Blue conservé 24 h
```

Durée typique : 20 à 30 minutes, dont 10 d'observation.

## Si quelque chose se passe mal

| Symptôme | Action |
|---|---|
| Échec des tests de fumée sur Green | Aucune bascule n'a eu lieu. Le trafic est toujours sur Blue. Analyser les journaux de Green, corriger, recommencer. **Aucun utilisateur n'a été affecté.** |
| Seuils dépassés pendant l'observation | Bascule arrière automatique. Vérifier que le trafic est revenu sur Blue : `./scripts/deploy.sh --env=prod --etape=etat` |
| Problème découvert après les 10 minutes | RB-03, mécanisme 1 (bascule arrière) — quelques secondes. |
| Problème découvert après 24 h | RB-03, mécanisme 2 (redéploiement d'image) — quelques minutes. |
| Données corrompues par une migration | RB-03, mécanisme 3 (restauration) — **dernière extrémité**. |

## Mode dégradé — déploiement manuel

Si GitHub Actions est indisponible, la procédure du SDD §26.5 reste exécutable :

```bash
./scripts/deploy.sh --env=prod --mode=manuel
```

Le script déroule les huit étapes en demandant confirmation à chacune. Il ne
remplace pas l'autorisation hiérarchique : celle-ci doit être obtenue par un
autre canal et consignée au journal de déploiement.

## Après le déploiement

- Vérification différée à T+30 min : automatique (SLO et chaîne d'audit).
- Communication de fin de maintenance : courriel + retrait du bandeau.
- Consigner au journal de déploiement : version, opérateur, approbateurs, durée,
  incidents éventuels.
