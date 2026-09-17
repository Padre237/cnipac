# ADR-038 — Encoder les SLO en regles Prometheus verifiees en continu

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + exploitation CENADI
- **Perimetre** : technique
- **Exigences concernees** : **NFR-C1-01 a C1-07**, **NFR-C2-01 a C2-06**, NFR-C3-08, SDD §27.2

## Contexte

Le SRS chapitre 10 fixe des exigences non fonctionnelles **toutes chiffrees et toutes
assorties d'une methode de verification** : P95 <= 800 ms, disponibilite 99,5 % en heures
ouvrees, RTO <= 4 h, RPO <= 1 h, 200 utilisateurs simultanes. Le SDD §27.2 annonce des SLI et
des SLO sans les instancier.

Le probleme habituel est que ces exigences sont verifiees **une fois**, en recette, puis
jamais. Un systeme qui tenait 800 ms en decembre 2026 peut en tenir 2 000 en juin 2027 sans
que personne ne le sache avant la plainte d'un utilisateur — et ces exigences sont
contractuelles.

## Decision

Chaque exigence chiffree du chapitre 10 du SRS devient **une regle Prometheus nommee d'apres
son identifiant d'exigence**.

| Regle | Exigence | Expression | Alerte |
|---|---|---|---|
| `cnipac:slo_api_p95` | NFR-C1-02 | P95 des requetes API authentifiees sur 7 jours glissants | > 800 ms pendant 15 min |
| `cnipac:slo_carte_p95` | NFR-C1-01 | P95 du chargement initial de la carte | > 5 s pendant 15 min |
| `cnipac:slo_dispo_ouvree` | NFR-C2-01 | Disponibilite lun-ven 07h-19h Africa/Douala | < 99,5 % sur 30 jours |
| `cnipac:slo_dispo_globale` | NFR-C2-02 | Disponibilite 24/7 | < 99,0 % mensuel |
| `cnipac:rpo_retard_wal` | NFR-C2-04 | Age du dernier WAL archive | > 15 min |
| `cnipac:sauvegarde_fraicheur` | NFR-C2-05 | Age de la derniere sauvegarde reussie | > 26 h |
| `cnipac:export_volumineux` | NFR-C4-04 | Exports de plus de 100 fiches | toute occurrence, notification a l'administrateur metier |
| `cnipac:bruteforce` | NFR-C3-08 | Echecs d'authentification par IP et par compte | > 5 / 10 min |
| `cnipac:audit_chaine` | NFR-C3-05 | Verification de la chaine de hachage du journal d'audit | toute rupture — **criticite maximale** |

**Nommage par identifiant d'exigence** : lorsqu'une alerte se declenche, le nom de la regle
renvoie directement a l'exigence contractuelle concernee. L'exploitant n'a pas a chercher si
l'incident est grave : l'exigence le dit.

**Budget d'erreur.** NFR-C2-02 (99,0 % mensuel) autorise environ **7 h 18 min**
d'indisponibilite par mois. Ce budget est calcule et affiche sur le tableau de bord Grafana.
Regle d'exploitation : au-dela de 75 % du budget consomme, les deploiements non critiques
sont suspendus jusqu'au mois suivant. Le budget d'erreur devient un instrument de decision,
pas un indicateur decoratif.

**Verification continue de la chaine d'audit.** Une tache planifiee recalcule la chaine de
hachage du journal d'audit et expose le resultat en metrique. Une rupture est l'evenement le
plus grave que le systeme puisse connaitre : elle signifie soit une corruption, soit une
alteration. Elle declenche une alerte de criticite maximale et la procedure de reponse a
incident du SDD §23.12.

**Trois tableaux de bord Grafana**, provisionnes en code dans `infra/monitoring/grafana/` :

1. **Conformite SRS** — une tuile par exigence chiffree, verte ou rouge. C'est le tableau a
   projeter lors des ateliers A1, A2, A3 et devant le COPIL.
2. **Exploitation** — latence, debit, erreurs, saturation (methode RED/USE).
3. **Metier** — fiches en quarantaine, delai median de validation, propositions de
   crowdsourcing en attente, taux de couverture du referentiel par region.

Le tableau de bord metier n'est pas un supplement : le delai median de validation est
l'indicateur qui revele le plus tot un engorgement du processus ANC, principal risque
operationnel identifie au SRS §13.4.3.

**Correlation des journaux.** Chaque requete porte un identifiant de correlation, journalise
par pino (SDD §4.2) et indexe par Loki. Un incident se remonte de l'alerte a la trace en deux
clics.

## Consequences

**Positives** — Les exigences non fonctionnelles sont verifiees en permanence, pas une fois
en recette. La derive est detectee avant la plainte. Le tableau de bord de conformite fournit
la preuve continue attendue par les criteres d'acceptation et par l'audit AC-P3-05.

**Negatives / couts** — Regles et tableaux de bord a ecrire et a maintenir (estime : 3 a 4
jours au Sprint 5). Risque de fatigue d'alerte si les seuils sont mal calibres : seules les
alertes de criticite maximale notifient en dehors des heures ouvrees, les autres attendent le
jour ouvre suivant.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative | Raison du rejet |
|---|---|
| Verification des NFR en recette uniquement | Ne detecte aucune derive en exploitation. Les exigences sont contractuelles pendant toute la duree du marche. |
| Supervision technique sans lien aux exigences | Produit des alertes dont personne ne sait dire si elles sont contractuellement graves. |
| Service de supervision externe | Contraire a NFR-C9-01 et NFR-C9-02 pour les metriques applicatives. Une sonde de disponibilite externe reste toutefois necessaire (NFR-C2-01 « sonde externe ») : elle ne transporte aucune donnee metier. |

## Mise en oeuvre

`infra/monitoring/prometheus/rules/`, `infra/monitoring/grafana/dashboards/`,
`infra/monitoring/prometheus/prometheus.yml`, `apps/backend/src/common/metrics/`,
`docs/runbooks/RB-06-astreinte-et-alertes.md`.
