# Conventions Git

**ADR** : [016](../adr/ADR-016-modele-de-branches.md), [036](../adr/ADR-036-conventional-commits.md)

## Branches

```
main                      protégée, toujours déployable
├── feat/CNIPAC-123-slug  72 h maximum
├── fix/CNIPAC-124-slug   72 h maximum
└── hotfix/CNIPAC-125     moins de 24 h
```

Pas de branche `develop`. Pas de branche `release/*`. Le SRS §14.8 prescrit le
trunk-based ; le workflow d'exemple du SDD §26.4 contenait une incohérence sur
ce point, tranchée par l'ADR-016 en faveur du SRS.

**La limite de 72 heures n'est pas une contrainte de vitesse.** Une branche qui
vit plus longtemps signale un ticket mal découpé. Si un développement doit
dépasser ce délai, il passe derrière un feature flag et fusionne par morceaux.

## Messages de commit

```
type(portée): sujet à l'impératif, en français

Corps facultatif, expliquant le POURQUOI plutôt que le comment.

Refs: CNIPAC-123
```

**Types** : `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci`
`chore` `revert`

**Portées** : `m1`…`m7` · `backend` `frontend` `shared` `db` `infra` `ci` `docs`
`deps` `security` `i18n` `a11y` `release`

La portée n'est pas décorative : `git log --grep "(m6)"` donne l'historique
complet d'un module, information utile aux rapports d'avancement du COPIL.

### Exemples

```
feat(m1): ingérer les soumissions Kobo en zone de quarantaine

Met en œuvre FR-M1-02 et RG-M1-01. L'idempotence repose sur l'identifiant de
soumission Kobo, conservé à vie conformément à RG-M1-04.

Refs: CNIPAC-42
```

```
fix(m2): exclure de la carte les producteurs hors enveloppe Cameroun

RG-M2-03. Les fiches concernées restent consultables dans la liste.

Refs: CNIPAC-88
```

```
feat(m7)!: passer l'API publique en v2

BREAKING CHANGE: le champ `reseau` devient un objet au lieu d'une chaîne.
v1 reste servie 12 mois avec en-têtes Deprecation et Sunset (ADR-037).

Refs: CNIPAC-201
```

## Pull requests

- Titre au format Conventional Commits — c'est lui qui devient le message de
  commit, la fusion se faisant en squash.
- Modèle de PR rempli, exigences couvertes renseignées.
- **Deux approbations**, dont un CODEOWNER (SRS §14.8).
- Toutes les vérifications au vert.
- Au-delà de 800 lignes ajoutées, la CI émet un avertissement : découper.

## Tags

```bash
git tag -s v0.1.0 -m "P1 — prototype minimaliste"
git push origin v0.1.0
```

Le tag doit être **annoté et signé** : le workflow de release refuse de
construire autrement. Les versions de jalon sont fixées par le SRS §14.8 :
P1 = `v0.1.0`, P2 = `v0.5.0`, P3 = `v1.0.0`.
