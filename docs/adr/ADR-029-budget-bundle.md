# ADR-029 — Appliquer un budget de bundle bloquant en CI

- **Statut** : ACCEPTE
- **Date** : 2026-09-17
- **Decideur** : tech lead
- **Perimetre** : technique et **metier**
- **Exigences concernees** : **NFR-C1-07**, **NFR-C1-01**, **NFR-C1-06**, contrainte technique SRS §2.4.2

## Contexte

Le SRS fixe trois exigences de poids, directement liees a la realite du terrain camerounais :

- **NFR-C1-07** : bundle initial <= **2 Mo gzip** ;
- **NFR-C1-01** : carte affichee en <= 5 s sur 3G de reference (1 Mbit/s, 100 ms) ;
- **NFR-C1-06** : <= 5 Mo de donnees pour un parcours type.

Le SRS §2.4.2 rappelle le contexte : connectivite faible, disparites regionales, mode
degrade attendu en 2G/Edge. A 1 Mbit/s, 2 Mo se telechargent en **16 secondes** dans le cas
ideal. La marge est deja mince — et le SDD §25.8 prevoit de verifier NFR-C1-07 par
« analyse bundle », sans preciser ni quand ni avec quel effet.

Un budget de poids qui n'est pas applique automatiquement n'est jamais tenu. Le poids ne se
degrade pas d'un coup : il augmente de 40 ko par PR, et personne ne remarque rien avant que
l'exigence ne soit dépassée de 60 %.

## Decision

`scripts/gate-bundle-budget.mjs`, execute apres chaque construction du frontend, bloquant en
PR.

| Metrique                                         | Budget     | Fondement                                                                  |
| ------------------------------------------------ | ---------- | -------------------------------------------------------------------------- |
| Bundle initial (entree + chunks critiques), gzip | **1,6 Mo** | NFR-C1-07 (2 Mo) avec 20 % de marge d'exploitation                         |
| **Seuil d'alerte**                               | 1,4 Mo     | Avertissement non bloquant : le probleme est signale avant d'etre bloquant |
| Chunk de la carte (`features/cartography`), gzip | 600 ko     | Leaflet + clustering                                                       |
| Chunk d'un module admin, gzip                    | 300 ko     | Chargement paresseux par route (SDD §20.3)                                 |
| Toute image statique                             | 200 ko     | WebP obligatoire                                                           |
| Total des polices                                | 150 ko     | Sous-ensemble latin uniquement                                             |

**Marge de 20 %** : le budget d'exigence est a 2 Mo, le budget applique a 1,6 Mo. Le systeme
doit avoir de la marge en production, pas frôler la limite.

**Regle de code-splitting opposable** (SDD §20.3) : aucune route administrative ne doit
apparaitre dans le chunk initial. Le controle echoue si le graphe de construction montre
`features/admin`, `features/crowdsourcing` ou `features/ingestion` dans l'entree — un
utilisateur anonyme consultant la carte ne doit jamais telecharger le code d'administration.

**Rapport de tendance** : chaque PR recoit un commentaire indiquant le delta de poids par
chunk. Un ajout de +40 ko devient visible au moment ou il est introduit.

**Depassement justifie** : possible via `docs/regles-metier/budget-bundle.json` avec
justification ecrite et validation du tech lead. Trace, jamais silencieux.

## Consequences

**Positives** — NFR-C1-07 est tenue par construction. Le cout d'une dependance lourde
devient visible a la PR, au moment de la decision, et non au test de charge de recette.
Protege directement l'experience des utilisateurs en zone mal couverte — objectif de terrain
du projet.

**Negatives / couts** — Certaines bibliotheques confortables seront refusees. Le controle
impose que la construction du frontend precede son execution, ce qui allonge la CI d'environ
une minute.

**Irreversibilite** — Nulle.

## Alternatives ecartees

| Alternative                      | Raison du rejet                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------- |
| Verification manuelle en recette | Trop tard : le poids est deja integre et sa reduction devient un chantier.                        |
| Lighthouse CI seul               | Mesure la performance percue, pas le poids par chunk. Complementaire (ADR-030), non substituable. |
| Budget a 2 Mo sans marge         | Aucune marge d'exploitation. Le premier depassement viole directement l'exigence contractuelle.   |

## Mise en oeuvre

`scripts/gate-bundle-budget.mjs`, `docs/regles-metier/budget-bundle.json`,
`apps/frontend/vite.config.ts` (`manualChunks`),
job `budget-bundle` de `.github/workflows/quality-gates.yml`.
