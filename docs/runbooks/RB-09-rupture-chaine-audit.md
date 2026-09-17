# RB-09 — Rupture de la chaîne du journal d'audit

> **Criticité maximale.** Cette alerte est la plus grave que le système puisse
> émettre. L'article 32 de la Loi n° 2024/001 impose l'immuabilité du journal
> d'audit. Une rupture signifie soit une corruption de données, soit une
> altération délibérée.

**Alerte** : `CnipacChaineAuditRompue` · **Exigences** : NFR-C3-05, art. 32 Loi 2024/001

## 1. Arrêter l'écriture — immédiatement

Ne rien corriger, ne rien redéployer, ne rien restaurer avant d'avoir figé
l'état. Toute écriture supplémentaire dégrade la valeur probatoire.

```bash
# Basculer l'application en lecture seule (le drapeau est lu à chaque requête).
ssh cnipac-prod
docker compose -f infra/compose/compose.app.yml exec backend \
  node dist/outils/mode-lecture-seule.js --activer --motif="RB-09 rupture chaine audit"
```

## 2. Figer les preuves

```bash
# Instantané chiffré de la table d'audit, horodaté, hors de la machine.
./scripts/figer-preuves-audit.sh --sortie=/srv/cnipac/preuves/

# Instantané pgBackRest immédiat, étiqueté.
docker compose -f infra/compose/compose.data.yml exec pgbackrest \
  pgbackrest --stanza=cnipac --type=full --annotation=motif=RB-09 backup
```

## 3. Localiser la rupture

```bash
./scripts/verifier-chaine-audit.sh --exhaustif --verbeux
```

La sortie indique le premier événement dont le hachage ne correspond plus. Noter
son identifiant, son horodatage et son acteur : ce sont les trois éléments du
rapport d'incident.

## 4. Qualifier — corruption ou altération ?

| Indice | Lecture probable |
|---|---|
| Rupture sur une plage **contiguë** d'identifiants, après un incident matériel ou un arrêt brutal | Corruption technique |
| Rupture sur **un ou quelques** événements isolés, sans incident concomitant | **Altération — suspicion d'acte délibéré** |
| Événements **manquants** (identifiants non contigus) | **Suppression — suspicion d'acte délibéré** |
| Somme de contrôle PostgreSQL en erreur (`data-checksums` est activé) | Corruption disque |

Croiser avec : les journaux système de la période, les accès SSH, les connexions
PostgreSQL (`log_connections` est activé), l'historique des déploiements.

## 5. Escalader

**Dans les deux cas** : informer le RSSI du CENADI et le chef de projet **dans
l'heure**.

**En cas de suspicion d'altération**, la procédure sort du champ technique :

- information du Directeur du CENADI et de la Direction des Archives Nationales ;
- conservation des preuves figées à l'étape 2 — elles peuvent être demandées par
  une autorité de contrôle ;
- ne pas restaurer ni réparer la table avant instruction explicite de la
  hiérarchie : une réparation détruirait les traces de l'altération.

Procédure de réponse à incident complète : SDD §23.12 (cinq phases).

## 6. Remise en service

Uniquement après qualification et instruction hiérarchique.

- **Corruption technique** : restauration PITR (RB-04) à un instant antérieur à
  la rupture, puis réapplication des WAL. Vérifier la chaîne avant réouverture.
- **Altération** : la remise en service est conditionnée à la clôture de
  l'instruction. La chaîne est reconstruite à partir du dernier point vérifié,
  et la reconstruction est elle-même journalisée comme un événement d'audit.

Dans les deux cas, ne rouvrir le service qu'après :

```bash
./scripts/verifier-chaine-audit.sh --exhaustif   # doit retourner intacte=true
./scripts/tests-de-fumee.sh --strict
```

## 7. Après l'incident

Post-mortem sans recherche de faute (SDD §23.12), présenté au COPIL. Si
l'altération est confirmée, réexaminer : les droits PostgreSQL sur la table
d'audit, l'accès SSH aux hôtes, et l'opportunité d'un stockage WORM externe
pour le journal.
