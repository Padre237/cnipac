# ADR-022 — Rendre la persistance Redis obligatoire (liste de revocation JWT)

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + RSSI
- **Perimetre** : technique et **securite**
- **Exigences concernees** : FR-M6-02, UC-M6-02, NFR-C3-08, RG-M6-yy, art. 32 Loi 2024/001

## Contexte

Le SDD §4.2 (ADR-003) retient Redis pour trois usages : cache applicatif, limitation de
debit, et **« cache de sessions JWT (revocation cote serveur) »**. Le troisieme usage change
la nature du composant.

Un cache est par definition reconstructible : le perdre degrade la performance, rien de
plus. Une **liste de revocation** est un element de securite. Si le conteneur Redis
redemarre sans persistance, la liste repart vide — et **tous les jetons revoques
redeviennent valides** jusqu'a leur expiration naturelle.

Le scenario concret : un administrateur desactive un compte compromis via UC-M6-02. Le jeton
en cours est ajoute a la liste de revocation. Une heure plus tard, une mise a jour de
l'image Redis redemarre le conteneur. **Le compte desactive redevient utilisable.** La
desactivation aura pourtant ete tracee au journal d'audit comme effective : le systeme ment
sur son propre etat de securite, ce qui contrevient a l'esprit de l'article 32 de la Loi
2024/001.

Le SDD §26.3 declare bien un volume `redis_data`, mais **n'active aucune persistance** dans
la commande du service. Un volume monte sur un Redis sans persistance configuree ne
contient rien.

## Decision

**1. Persistance AOF activee**, avec `appendfsync everysec` — au plus une seconde de perte,
pour un cout de performance negligeable a cette volumetrie.

```yaml
redis:
  command: >
    redis-server
    --appendonly yes
    --appendfsync everysec
    --requirepass-file /run/secrets/redis_password
    --maxmemory 512mb
    --maxmemory-policy noeviction
  volumes:
    - /srv/cnipac/redis:/data
```

**2. `maxmemory-policy noeviction`** et non `allkeys-lru`. Sous pression memoire, une
politique d'eviction supprimerait des entrees **au hasard** — potentiellement des entrees de
revocation. Avec `noeviction`, Redis refuse les nouvelles ecritures et l'incident devient
visible plutot que silencieux.

**3. Separation des espaces de cles par base logique**, pour que la supervision distingue le
jetable du critique :

| Base | Usage                                  | Criticite                     |
| ---- | -------------------------------------- | ----------------------------- |
| `0`  | Cache applicatif (agregats M3, tuiles) | Jetable                       |
| `1`  | Limitation de debit (NFR-C3-08)        | Degradation acceptable        |
| `2`  | **Liste de revocation JWT**            | **Critique — perte = faille** |

**4. Defense en profondeur.** La liste de revocation est **reconstructible depuis
PostgreSQL** : au demarrage, le backend recharge dans la base 2 les jetons des comptes
desactives ou dont les roles ont change depuis une duree inferieure a la duree de vie
maximale d'un jeton. Redis reste le chemin rapide ; PostgreSQL reste la source de verite.
Un composant de securite ne doit pas dependre d'un composant en memoire.

**5. Duree de vie des jetons d'acces limitee a 15 minutes** (SDD §6.5.4), ce qui borne la
fenetre d'exposition residuelle meme en cas de defaillance conjointe des deux mecanismes.

## Consequences

**Positives** — La revocation devient fiable. Le systeme ne peut plus mentir sur l'etat de
desactivation d'un compte. Le rechargement depuis PostgreSQL fournit une garantie
independante de la disponibilite de Redis.

**Negatives / couts** — Ecritures disque continues (volume negligeable). Le fichier AOF
croit et doit etre compacte ; `auto-aof-rewrite-percentage 100` s'en charge. Le
rechargement au demarrage ajoute quelques centaines de millisecondes au temps de demarrage
du backend.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                                               | Raison du rejet                                                                                          |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Redis sans persistance, conforme a la lettre du SDD §26.3 | Reintroduit silencieusement des jetons revoques. Faille de securite caracterisee.                        |
| Persistance RDB (instantanes)                             | Fenetre de perte de plusieurs minutes entre deux instantanes. Insuffisant pour de la revocation.         |
| Liste de revocation en PostgreSQL uniquement              | Ajoute une lecture en base a **chaque requete authentifiee**, en tension avec NFR-C1-02 (P95 <= 800 ms). |
| Jetons non revocables, expiration courte seule            | Contraire a FR-M6-02 et a UC-M6-02, qui exigent une desactivation a effet immediat.                      |

## Mise en oeuvre

`infra/compose/compose.data.yml`, `apps/backend/src/modules/m6-admin/` (service de
rechargement au demarrage), `infra/monitoring/prometheus/rules/securite.yml`
(alerte `CnipacRedisRevocationIndisponible`).
