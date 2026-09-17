import { defineConfig } from 'vitest/config';

// ADR-028 : 100 % exige sur ce paquet. Les regles de gestion sont pures et sans
// dependance : il n'y a aucune raison de ne pas les couvrir integralement.
export default defineConfig({
  test: {
    globals: false,
    include: ['src/**/*.spec.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.spec.ts', 'src/index.ts'],
      thresholds: { lines: 100, functions: 100, branches: 95, statements: 100 },
    },
  },
});
