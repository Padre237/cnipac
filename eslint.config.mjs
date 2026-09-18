// Configuration ESLint de la racine du monorepo.
//
// lint-staged et les appels `eslint` lancés depuis la racine ont besoin d'une
// configuration à cet emplacement : ESLint 9 ne remonte plus l'arborescence.
// `projectService` résout automatiquement le tsconfig le plus proche de chaque
// fichier, si bien qu'une seule configuration couvre les quatre paquets.
import config from '@cnipac/eslint-config';

export default [
  {
    ignores: [
      '**/dist/**', '**/coverage/**', '**/node_modules/**',
      'docs/**', 'infra/**', 'scripts/**', 'tests/load/**',
      '**/*.config.js', '**/*.config.mjs', '**/*.config.ts',
    ],
  },
  ...config,
  { languageOptions: { parserOptions: { tsconfigRootDir: import.meta.dirname } } },
];
