# Guide du développeur

Objectif du SDD §4 : cloner le dépôt, lancer une commande, obtenir un
environnement fonctionnel **en moins de quinze minutes**.

## Démarrage

```bash
git clone git@github.com:cenadi-cm/cnipac.git && cd cnipac

# Node 22 LTS (SDD §4.2) — voir .nvmrc
npm install                    # lockfile gelé : aucune surprise
cp .env.example .env

docker compose -f infra/compose/compose.ci.yml up -d postgres redis
npm run exec -w @cnipac/backend prisma migrate dev
npm run exec -w @cnipac/backend prisma db seed    # 50 producteurs synthétiques

npm run start:dev -w @cnipac/backend   # http://localhost:3000
npm run dev -w @cnipac/frontend        # http://localhost:5173
```

## pnpm en une minute

Si vous venez de npm, les commandes usuelles sont homonymes.

| npm                               | pnpm                                 |
| --------------------------------- | ------------------------------------ |
| `npm install`                     | `npm install`                        |
| `npm run build`                   | `npm run build`                      |
| `npm install -w apps/backend pkg` | `npm run add -w @cnipac/backend pkg` |
| `npm ci`                          | `npm install --frozen-lockfile`      |

La différence qui compte : **pnpm refuse d'importer un paquet non déclaré**. Si
une importation échoue alors qu'elle « marchait avant », c'est une dépendance
fantôme — ajoutez-la aux dépendances du paquet qui l'utilise. C'est précisément
ce que l'ADR-018 cherche à empêcher.

## Avant d'ouvrir une pull request

```bash
npm run lint && npm run typecheck && npm run test:unit && npm run gate:all
```

Ces commandes sont exactement celles qu'exécute la CI. Les faire tourner en
local évite la majorité des retours rouges.

## Écrire un test — la convention qui compte

Le nom du test porte entre crochets l'identifiant de l'exigence couverte :

```ts
it('[RG-M2-03] les producteurs hors enveloppe Cameroun ne sont pas cartographiés', () => {
  expect(coordonneesDansEnveloppeCameroun(48.85, 2.35)).toBe(false);
});
```

`scripts/gate-tracabilite.mjs` échoue si un test référence un identifiant
inconnu, et si une règle de gestion n'a aucun test dédié. La matrice de
traçabilité (SRS chap. 15) est reconstruite à partir de ces marqueurs — elle
reste donc vraie sans que personne ne la maintienne (ADR-035).

## Où mettre quoi

| Nature                                             | Emplacement                                  | Pourquoi                                                   |
| -------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------- |
| Énumération ou seuil métier                        | `packages/shared-types`                      | Source de vérité unique, consommée par le back et le front |
| Règle de gestion pure                              | `packages/shared-types/src/regles-metier.ts` | Testable unitairement, 100 % de couverture exigée          |
| Logique d'un module                                | `apps/backend/src/modules/mX-*/`             | Découpage du SRS chapitre 5                                |
| Composant utilisé par une seule fonctionnalité     | `src/features/<f>/components/`               | SDD §20.2                                                  |
| Composant utilisé par deux fonctionnalités ou plus | `src/shared/components/`                     | Il « monte » à la deuxième utilisation                     |

## Erreurs qui coûtent cher

- **Écrire une valeur métier en dur.** Un statut, un seuil, un code de rôle
  écrit en clair dans un module finit par diverger. ESLint en refuse certains ;
  les autres relèvent de la revue.
- **Ajouter une dépendance sans regarder sa licence.** La CI la refusera
  (ADR-025), après que vous aurez écrit le code qui l'utilise.
- **Ajouter une bibliothèque lourde au frontend.** Le budget de bundle est à
  1,6 Mo gzip. Vérifiez avant, pas après.
- **Écrire une migration destructive.** Voir [MIGRATIONS.md](MIGRATIONS.md).
- **Oublier les traductions.** Toute chaîne visible existe en français **et** en
  anglais (NFR-C8-01, art. 58 de la Loi 2024/001).
