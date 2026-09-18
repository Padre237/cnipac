# ADR-026 — Codecov, conformement au SDD §26.4

- **Statut** : **REVISE — derogation retiree**, le SDD fait foi
- **Date** : 2026-09-17
- **Decideur** : architecte CENADI + RSSI
- **Perimetre** : technique
- **Exigences concernees** : **NFR-C6-01**, NFR-C9-02, NFR-C9-03, SDD §25.8

> **Cet ADR est ANNULE.** La derogation proposant l'abandon de Codecov est
> **retiree** sur instruction du maitre d'ouvrage.
>
> **Decision retenue : Codecov**, via `codecov/codecov-action@v4`, exactement
> comme l'ecrit le SDD §26.4. Le secret `CODECOV_TOKEN` est a renseigner au
> niveau de l'organisation GitHub.
>
> Les seuils de couverture restent appliques **localement** par Jest et Vitest
> (`coverageThreshold`), ce qui n'est pas une derogation mais la mise en oeuvre
> de NFR-C6-01 : l'exigence doit etre verifiable en local comme en CI.
>
> Point signale au COPIL pour information : Codecov est un service SaaS etranger,
> auquel sont transmis les chemins de fichiers et la structure interne du
> systeme. Ce point est en tension avec NFR-C9-02 et NFR-C9-03. Il ne fait
> l'objet d'aucune demande de derogation.

---

_Le texte qui suit est conserve a titre de trace de l'analyse initiale._

## Contexte

Le workflow d'exemple du SDD §26.4 contient `uses: codecov/codecov-action@v4`. Codecov est
un service SaaS commercial heberge aux Etats-Unis. Son usage implique la transmission a un
tiers etranger des rapports de couverture — lesquels contiennent **les chemins de fichiers,
les noms de fonctions et la structure interne complete** du systeme.

Trois objections :

1. **NFR-C9-03** exige une stack integralement open source. Codecov ne l'est pas.
2. **NFR-C9-02** interdit la sortie de territoire des donnees sensibles. Un rapport de
   couverture n'est pas une donnee nominative, mais il cartographie la structure interne d'un
   systeme d'Etat — information dont l'exposition a un tiers n'est pas anodine.
3. **Dependance operationnelle** : une indisponibilite de Codecov bloquerait la CI, donc les
   fusions, pour un service qui n'apporte que de la visualisation.

Un precedent aggrave le point 3 : la compromission du _bash uploader_ de Codecov en 2021 a
permis l'exfiltration de variables d'environnement, donc de secrets, depuis les CI de ses
clients. Ce type d'incident est exactement ce que NFR-C9 cherche a prevenir.

## Decision

Aucun service externe de couverture. Le dispositif repose sur trois mecanismes internes.

**1. Seuils appliques par les outils eux-memes.** Jest (`coverageThreshold`) et Vitest
(`coverage.thresholds`) font echouer la commande de test si les seuils d'ADR-028 ne sont pas
atteints. C'est le mecanisme bloquant : il fonctionne en local exactement comme en CI, ce que
Codecov ne permet pas.

**2. Rapports publies comme artefacts.** Rapport HTML et LCOV joints a chaque execution,
conserves 30 jours, telechargeables par tout membre de l'equipe.

**3. Synthese en commentaire de PR.** `scripts/gate-coverage.mjs` lit les rapports LCOV,
compare a la reference de `main`, publie un tableau par module et **echoue si la couverture
regresse de plus de 0,5 point** sans justification. Le comportement utile de Codecov est ainsi
reproduit sans service externe, en une centaine de lignes de Node.

Un badge de couverture est genere localement et committe dans le `README.md` a chaque release,
satisfaisant la demande du SDD §25.8 (« badge dans le README »).

## Consequences

**Positives** — Aucune donnee de structure ne quitte le territoire. Aucun secret expose a un
tiers. La CI ne depend plus de la disponibilite d'un service commercial. Les seuils sont
verifiables en local avant meme d'ouvrir une PR.

**Negatives / couts** — Perte de l'interface web historique de Codecov (graphes de tendance,
navigation par fichier). Compense partiellement par l'artefact HTML et le commentaire de PR.
Environ 150 lignes de script a maintenir.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                      | Raison du rejet                                                                                                                     |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Codecov, conforme au SDD §26.4   | Contredit NFR-C9-02 et NFR-C9-03. Dependance a un service dont l'historique de securite est charge.                                 |
| SonarQube Community auto-heberge | Apporte davantage (qualite, duplication, securite) mais ajoute un service critique a exploiter. A reevaluer en Phase 2 post-pilote. |
| Aucun suivi de tendance          | Laisse la couverture deriver sans signal. NFR-C6-01 impose un seuil, donc un suivi.                                                 |

## Mise en oeuvre

`apps/backend/jest.config.ts`, `apps/frontend/vitest.config.ts`,
`scripts/gate-coverage.mjs`, job `couverture` de `.github/workflows/ci.yml`.
