// Configuration ESLint — reprend les regles partagees du monorepo (ADR-013).
// NFR-C6-04 : aucune erreur ni avertissement n'est tolere en CI.
import config from '@cnipac/eslint-config';

export default [
  ...config,
  { languageOptions: { parserOptions: { tsconfigRootDir: import.meta.dirname } } },
];
