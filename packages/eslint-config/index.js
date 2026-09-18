import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import a11y from 'eslint-plugin-jsx-a11y';

/**
 * Regles de lint partagees — NFR-C6-04 (zero erreur toleree en CI).
 * La configuration privilegie les regles qui attrapent des DEFAUTS, pas celles
 * qui arbitrent des questions de style : le style est traite par Prettier.
 */
export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: { parserOptions: { projectService: true } },
    rules: {
      // Le typage est la premiere ligne de defense (SDD §4.2).
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      // Une promesse non attendue dans un traitement d'ingestion produit des
      // pertes silencieuses de soumissions (module M1).
      '@typescript-eslint/require-await': 'error',
      '@typescript-eslint/switch-exhaustiveness-check': 'error',

      // Empeche la reintroduction de valeurs metier en dur : elles doivent
      // venir de @cnipac/shared-types (ADR-013).
      'no-restricted-syntax': [
        'error',
        {
          selector: "Literal[value=/^CMR-[A-Z]{3}-/]",
          message: "Le format du code producteur est defini par MOTIF_CODE_PRODUCTEUR dans @cnipac/shared-types (RG-M1-02).",
        },
        {
          selector: "TSAsExpression > TSAnyKeyword",
          message: "Les conversions vers 'any' masquent des defauts de typage.",
        },
      ],

      // Une valeur de statut ecrite en clair contourne l'automate RG-M1-05.
      'no-restricted-imports': ['error', { patterns: [{ group: ['../../*'], message: "Utiliser l'alias @/ plutot qu'une remontee de plus de deux niveaux." }] }],

      'no-console': ['error', { allow: ['warn', 'error'] }],
      eqeqeq: ['error', 'always'],
    },
  },
  {
    files: ['**/*.tsx'],
    plugins: { 'jsx-a11y': a11y },
    rules: {
      // ADR-030 — l'accessibilite est bloquante. Ces regles attrapent a la
      // compilation ce qu'axe-core attraperait a l'execution.
      ...a11y.configs.recommended.rules,
      'jsx-a11y/alt-text': 'error',
      'jsx-a11y/anchor-is-valid': 'error',
      'jsx-a11y/label-has-associated-control': 'error',
      'jsx-a11y/no-autofocus': 'error',
    },
  },
  {
    // Outils en ligne de commande : seeds, generateurs, scripts d'exploitation.
    // La sortie console y est la fonction meme du programme, et non une trace
    // de debogage oubliee.
    files: ['**/prisma/seed.ts', '**/src/outils/**', '**/scripts/**'],
    rules: {
      'no-console': 'off',
      '@typescript-eslint/require-await': 'off',
    },
  },
  {
    // Un module NestJS est, par construction, une classe vide porteuse d'un
    // decorateur @Module. La regle no-extraneous-class ne s'y applique pas.
    files: ['**/*.module.ts'],
    rules: { '@typescript-eslint/no-extraneous-class': 'off' },
  },
  {
    files: ['**/*.spec.ts', '**/*.spec.tsx', '**/*.test.ts', 'tests/**'],
    rules: {
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-non-null-assertion': 'off',
      'no-restricted-syntax': 'off',
    },
  },
  { ignores: ['dist/**', 'coverage/**', 'node_modules/**', '**/*.config.js'] },
);
