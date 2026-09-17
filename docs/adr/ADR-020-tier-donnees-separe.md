# ADR-020 — Pile Compose unique et volumes nommes, conformement au SDD §26.3

- **Statut** : **REVISE — derogation retiree**, le SDD fait foi
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + tech lead
- **Perimetre** : technique
- **Exigences concernees** : NFR-C2-03 (RTO), NFR-C2-04 (RPO), NFR-C5-03, NFR-C5-05, NFR-C2-06

> **Cet ADR est ANNULE.** La derogation proposant trois piles Compose separees
> et un bind mount dedie est **retiree** sur instruction du maitre d'ouvrage.
>
> **Decision retenue : la forme du SDD §26.3** — un `docker-compose.yml` commun
> et trois overrides (`dev`, `preprod`, `prod`), volumes Docker **nommes**
> (`postgres_data`, `redis_data`), conteneurisation integrale de la base de
> donnees conformement au SDD §26.1 et a l'arbitrage du tech lead.
>
> Deux parametres d'execution, que le SDD ne specifie pas et qui ne modifient
> donc aucune decision de conception, sont conserves :
> - `shm_size: 1gb` sur le service PostgreSQL — sans quoi les vues materialisees
>   du module M3 (SDD §12.10) provoquent des `could not resize shared memory
>   segment` intermittents ;
> - `scripts/deploy.sh` refuse l'option `-v` / `--volumes`, qui detruirait les
>   volumes nommes de production.
>
> Point signale au COPIL pour information : les volumes nommes restent sensibles
> a `docker compose down -v` et a `docker system prune --volumes`. La protection
> est desormais procedurale (runbook RB-05), non technique.

---

*Le texte qui suit est conserve a titre de trace de l'analyse initiale.*

## Contexte

Le tech lead a arbitre la conteneurisation integrale, base de donnees comprise. Cette
orientation est **conforme** au SDD §26.1 et §26.3, qui decrivent deja un service
`postgres: image: postgis/postgis:16-3.4` avec un volume `postgres_data`. Elle est aussi la
bonne decision : il n'existe pas de PostgreSQL manage souverain au Cameroun, et un PostgreSQL
installe a la main sur l'hote serait non reproductible, donc contraire a NFR-C5-05.

Trois defauts du montage decrit au SDD §26.3 doivent toutefois etre corriges avant la mise
en production.

**1. Volume nomme.** `volumes: postgres_data: {}` place PGDATA dans
`/var/lib/docker/volumes`. Les donnees dependent alors du cycle de vie du demon Docker :
un `docker compose down -v`, un `docker system prune --volumes` ou une reinstallation du
demon les detruit. Aucune de ces trois commandes n'est exotique en exploitation.

**2. Pile unique.** La procedure §26.5 etape 5 lance `docker compose up -d`. Si les services
applicatifs et la base partagent un meme fichier Compose, **chaque release applicative
touche le conteneur PostgreSQL**. Le jour ou le tag `16-3.4` recoit une nouvelle
construction amont, un deploiement de routine redemarre la base de production sans que
personne ne l'ait decide.

**3. `/dev/shm` a 64 Mo.** Docker alloue par defaut 64 Mo de memoire partagee. PostgreSQL
s'en sert pour les requetes paralleles — et les vues materialisees des tableaux de bord M3
(SDD §12.10) en declenchent. Le symptome est un `ERROR: could not resize shared memory
segment` intermittent, sous charge, en production : parmi les incidents les plus couteux a
diagnostiquer.

## Decision

**1. Trois piles Compose distinctes, a cycles de vie independants :**

| Fichier | Services | Frequence de redemarrage |
|---|---|---|
| `infra/compose/compose.data.yml` | `postgres`, `redis`, `pgbackrest` | Fenetre de maintenance planifiee uniquement |
| `infra/compose/compose.app.yml` | `backend`, `frontend`, `nginx` | A chaque release |
| `infra/compose/compose.obs.yml` | `prometheus`, `grafana`, `loki`, `*-exporter` | Independante |

Le pipeline de deploiement continu ne pilote **que** `compose.app.yml`. Le tier donnees
possede son propre runbook (`RB-05`) et n'est jamais touche par un deploiement applicatif.

**2. Bind mount sur partition dediee.** PGDATA vit dans `/srv/cnipac/pgdata`, sur une
partition distincte de celle du systeme. Trois benefices : les donnees survivent a toute
operation Docker, la partition est supervisee independamment, et un systeme de fichiers
plein cote OS ne corrompt pas la base.

**3. `shm_size: 1gb`** sur le service `postgres`.

**4. `postgresql.conf` versionne** et monte en lecture seule. Les parametres memoire sont
explicites, calibres sur les 16 Go de l'hote H2 (SDD §8.3) : `shared_buffers=4GB`,
`effective_cache_size=12GB`, `work_mem=16MB`, `maintenance_work_mem=1GB`. Les valeurs par
defaut de l'image ne connaissent rien du dimensionnement de l'hote.

**5. Limites memoire deliberees.** Aucune limite Docker inferieure au besoin reel de
PostgreSQL : un depassement provoquerait un arret par l'OOM killer, donc une recuperation
apres crash. `mem_limit` est fixe a 14 Go sur un hote de 16 Go.

**6. Garde-fou operationnel.** `scripts/deploy.sh` refuse toute invocation contenant `-v`
ou `--volumes`, et refuse de s'executer sur `compose.data.yml` sans la variable explicite
`CNIPAC_MAINTENANCE_DATA=1`.

## Consequences

**Positives** — Les donnees de production ne dependent plus du cycle de vie de Docker. Les
deploiements applicatifs ne peuvent plus redemarrer la base. Le defaut `/dev/shm` est
neutralise avant d'avoir produit son premier incident.

**Negatives / couts** — Trois fichiers Compose au lieu d'un : une procedure legerement plus
longue a expliquer en formation. Le bind mount impose de gerer les droits POSIX du
repertoire (uid 999) au provisionnement de l'hote — scripte dans
`infra/host/bootstrap-hote.sh`.

**Irreversibilite** — Moyenne. Revenir a un volume nomme apres la mise en production
suppose une fenetre d'arret et une copie des donnees.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| PostgreSQL installe sur l'hote, hors conteneur | Rompt la parite environnementale (SDD §8.1) et la reproductibilite NFR-C5-05. C'est precisement ce que la conteneurisation integrale vient corriger. |
| Volume nomme conforme au SDD §26.3 | Expose les donnees de production aux commandes de maintenance Docker courantes. Risque juge inacceptable pour un referentiel national. |
| Fichier Compose unique conforme au SDD §26.5 | Couple le cycle de vie de la base a celui des releases applicatives. |

## Mise en oeuvre

`infra/compose/compose.data.yml`, `infra/compose/compose.app.yml`,
`infra/postgres/conf/postgresql.conf`, `infra/host/bootstrap-hote.sh`, `scripts/deploy.sh`,
`docs/runbooks/RB-05-maintenance-tier-donnees.md`.
