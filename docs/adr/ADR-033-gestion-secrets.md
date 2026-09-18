# ADR-033 — Gerer les secrets par Docker secrets et GitHub Environments, avec rotation

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : RSSI + architecte CENADI
- **Perimetre** : technique et **securite**
- **Exigences concernees** : NFR-C3-02, NFR-C3-06, NFR-C9-02, SDD ADR-010, SDD §23.6

## Contexte

Le SDD ADR-010 retient « Docker secrets en P1, Vault a partir de P3 si requis », et le §26.3
montre des secrets lus depuis `./secrets/*.txt`. Le dispositif est correct au runtime mais
laisse trois questions ouvertes : d'ou viennent ces fichiers, qui les fait tourner, et
comment la CI accede aux secrets de deploiement sans les exposer.

## Decision

**Quatre categories, quatre traitements.**

| Categorie                                                                                                           | Stockage                                                                                                       | Acces                              | Rotation      |
| ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ------------- |
| Secrets applicatifs PROD (URL base, secret JWT, mot de passe Redis, jeton Kobo, cle de chiffrement des sauvegardes) | Fichiers `/srv/cnipac/secrets/*` sur l'hote, permissions `0400`, proprietaire `root`, montes en Docker secrets | Conteneur uniquement, via `*_FILE` | 90 jours      |
| Secrets de deploiement (cle SSH, jeton de registry, cle cosign)                                                     | **GitHub Environments** `preprod` / `production`, avec approbateurs requis                                     | Jobs CI autorises uniquement       | 180 jours     |
| Secrets de developpement                                                                                            | `.env` local, jamais versionne ; `.env.example` versionne avec valeurs factices                                | Poste developpeur                  | sans objet    |
| Secrets d'integration CI                                                                                            | Generes a la volee pour chaque execution, jetables                                                             | Job courant                        | par execution |

**Principe `*_FILE`** : le backend ne lit **jamais** un secret depuis une variable
d'environnement. Une variable d'environnement apparait dans `docker inspect`, dans
`/proc/<pid>/environ` et dans les traces d'erreur. Le SDD §26.3 applique deja ce principe ;
il est ici generalise et verifie : `scripts/gate-secrets.mjs` echoue si le code lit une
variable d'environnement dont le nom contient `SECRET`, `PASSWORD`, `TOKEN` ou `KEY` sans
passer par le chargeur `*_FILE`.

**Detection de fuites, bloquante.** `gitleaks` s'execute a chaque PR **et** sur l'historique
complet a chaque execution planifiee. Un secret committe puis retire reste dans l'historique
Git : la detection porte donc sur l'historique, pas seulement sur le diff.

**Amorcage.** `scripts/bootstrap-secrets.sh` genere les secrets sur l'hote avec une entropie
suffisante (32 octets aleatoires, base64), fixe les permissions et **n'affiche jamais les
valeurs**. Aucun secret ne transite par un canal de communication de l'equipe.

**Rotation.** Procedure `docs/runbooks/RB-07-rotation-des-cles.md`, exercee au moins une fois
avant la mise en production P3. Une procedure de rotation jamais executee ne fonctionne pas.
La rotation du secret JWT invalide toutes les sessions : elle s'execute en fenetre de
maintenance, avec information prealable des utilisateurs.

**Vault** : non retenu en P1/P2, conformement au SDD ADR-010. Condition de reexamen
explicite — au-dela de 15 secrets distincts ou de 3 hotes, le cout de gestion manuelle
depasse celui de Vault.

**Jamais de secret reel hors PROD** (ADR-034). Un jeton KoboToolbox de PREPROD ne doit
jamais pouvoir lire les soumissions reelles : un projet Kobo de test distinct est requis.

## Consequences

**Positives** — Aucun secret dans le depot, aucun secret dans l'environnement des processus.
La detection porte sur l'historique, pas seulement sur le dernier commit. L'approbation
GitHub Environment fait que meme un jeton CI compromis ne suffit pas a deployer en
production.

**Negatives / couts** — Les secrets vivent a deux endroits (hote et GitHub) : une rotation
doit etre faite aux deux. La procedure l'impose explicitement. Pas de journal d'acces aux
secrets, contrairement a Vault — limite assumee du dispositif P1.

**Irreversibilite** — Faible.

## Alternatives ecartees

| Alternative                          | Raison du rejet                                                                                                           |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| Variables d'environnement classiques | Exposees par `docker inspect`, `/proc`, et les traces d'erreur. Contraire a NFR-C3-02.                                    |
| Vault des P1                         | Contraire au SDD ADR-010. Ajoute un service critique (a sauvegarder, a sceller, a desceller) a une equipe de 4 personnes. |
| Fichier `.env` sur l'hote            | Lu par tout processus du conteneur, present dans les images de sauvegarde. Les Docker secrets sont montes en `tmpfs`.     |

## Mise en oeuvre

`scripts/bootstrap-secrets.sh`, `scripts/gate-secrets.mjs`,
`.github/workflows/security.yml` (job `detection-secrets`),
`infra/compose/compose.app.yml`, `.env.example`,
`docs/runbooks/RB-07-rotation-des-cles.md`.
