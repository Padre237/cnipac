# Base de données CNIPAC

PostgreSQL 16 + PostGIS 3.4, schéma unique `cnipac` (SDD §11.8).

## Provenance de chaque élément

| Élément                                           | Source                             | Nature                                                                     |
| ------------------------------------------------- | ---------------------------------- | -------------------------------------------------------------------------- |
| 13 types ENUM système                             | SDD §12.2                          | Transcription **littérale**                                                |
| Table `producteur`                                | SDD §12.3                          | Littérale + compléments Section II                                         |
| Table `version_fiche`                             | SDD §12.4                          | Transcription **littérale**                                                |
| Table `soumission_kobo`                           | SDD §12.5                          | Littérale + compléments                                                    |
| Table `utilisateur`                               | SDD §12.6                          | Transcription **littérale**                                                |
| Table `evenement_audit`                           | SDD §12.7                          | Transcription **littérale**                                                |
| Référentiels                                      | SDD §12.8                          | Transcription **littérale**                                                |
| Jonctions RBAC                                    | SDD §12.9                          | Transcription **littérale**                                                |
| `mv_kpi_national`, `mv_repartition_par_reseau`    | SDD §12.10                         | Transcription **littérale**                                                |
| `calculer_hash_evenement`, triggers d'immuabilité | SDD §12.7                          | Transcription **littérale**                                                |
| 20 types ENUM métier                              | Formulaire Kobo, feuille `choices` | Conception — Annexe A                                                      |
| Sections III à VIII                               | Formulaire Kobo + SRS §12.4-12.9   | Conception — Annexe A (voir [A-06](../../docs/ANOMALIES-DOCUMENTAIRES.md)) |
| Découpage administratif                           | Formulaire Kobo                    | **Généré** par script                                                      |
| Ministères                                        | TDR §7                             | À faire valider par les ANC                                                |

## Installation

```bash
# Conteneur : automatique à la création du volume
docker compose -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.dev.yml up -d postgres

# Manuelle
createdb cnipac
for f in infra/postgres/schema/*.sql infra/postgres/seed/2*.sql; do
  psql -d cnipac -v ON_ERROR_STOP=1 -f "$f"
done
```

## Validation

```bash
./scripts/valider-schema-sql.sh
```

Applique le schéma sur une base jetable puis exerce **38 assertions** : les
contraintes sont vérifiées en les faisant effectivement échouer. Une contrainte
qu'on n'a jamais vue refuser n'est pas une contrainte vérifiée.

## Régénérer les référentiels après modification du formulaire

```bash
python3 scripts/generer-seed-depuis-xlsform.py
```

Le découpage administratif et les libellés des listes ne sont jamais ressaisis :
ils sont extraits du XLSForm, qui fait foi.

## Correspondance formulaire → schéma

| Section du formulaire                         | Table                                                                        |
| --------------------------------------------- | ---------------------------------------------------------------------------- |
| Introduction (`intro`)                        | `soumission_kobo.date_remplissage`                                           |
| I — Identification (`identif`)                | `producteur`                                                                 |
| II — Localisation (`loc`)                     | `producteur` (geom, region/departement/commune, quartier, BP, rue, lieu-dit) |
| III — Centre de préarchivage (`resp_pers`)    | `centre_prearchivage` + `centre_personnel`                                   |
| IV — Patrimoine documentaire (`patrimoine`)   | `patrimoine_documentaire` + `patrimoine_support` + `archive_electronique`    |
| V — Évaluation de la conservation (`risques`) | `evaluation_conservation` + `piece_jointe` (photos)                          |
| VI — Maturité (`grp_maturite`)                | `maturite_archivistique` + `operation_elimination`                           |
| VII — Logistique (`grp_logistique`)           | `logistique_transfert`                                                       |
| VIII — Contact du répondant (`contact`)       | `contact_repondant` — **données nominatives**                                |

### Deux choix de modélisation à connaître

**Les choix multiples porteurs de quantité sont des tables de jonction.** Le
formulaire attache un volume à chaque support coché (`vol_papier`,
`nb_numerique`…) et un effectif à chaque type de personnel (`nb_arch_ass`…).
D'où `patrimoine_support` et `centre_personnel`, plutôt que des colonnes plates.

**Les choix multiples sans quantité sont des tableaux d'ENUM**, indexés en GIN.
Plus compact, et suffisant pour répondre à « quels producteurs présentent des
moisissures ? ».

## Ce que la base garantit elle-même

Ces règles ne dépendent pas de la couche applicative — le moteur les applique.

| Règle                                                   | Mécanisme                                                   |
| ------------------------------------------------------- | ----------------------------------------------------------- |
| **Art. 32 Loi 2024/001** — journal d'audit immuable     | Triggers INSERT-ONLY + chaînage SHA-256, `TRUNCATE` compris |
| **RG-M1-02** — code producteur immuable                 | `trg_producteur_code_immuable`                              |
| **RG-M1-04** — soumission Kobo conservée à vie          | Triggers d'immuabilité                                      |
| **RG-M1-05** — automate des statuts                     | `trg_producteur_transition_statut`                          |
| **RG-M2-01/02** — carte publique sans donnée nominative | `v_producteur_public`                                       |
| **RG-M2-03 / DQ-01** — enveloppe Cameroun               | `chk_producteur_geom_in_cameroun`                           |
| **RG-M3-01** — indice de maturité                       | `calculer_score_maturite()` + trigger                       |
| **RG-M3-02** — seuil d'agrégation de 5                  | Colonne `publiable` des vues matérialisées                  |
| **DQ-02** — sigle unique par ministère                  | `uq_producteur_sigle_ministere`                             |
| **DQ-04** — dates extrêmes cohérentes                   | `chk_patrimoine_dates_extremes`                             |
| **NFR-C3-06** — Argon2id                                | `utilisateur.hash_password`, jamais de clair                |

## Points à arbitrer

Voir [docs/ANOMALIES-DOCUMENTAIRES.md](../../docs/ANOMALIES-DOCUMENTAIRES.md) —
six points, dont deux à trancher **avant la collecte terrain** (A-02 et A-05).
