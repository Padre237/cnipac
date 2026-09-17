import type { Config } from 'jest';

/**
 * ADR-028 — seuils de couverture differencies par module.
 * Les valeurs correspondent au palier P0 ; elles sont relevees a chaque jalon
 * en meme temps que docs/regles-metier/palier-courant.json.
 * Les modules M1, M4 et M6 portent un seuil renforce : un defaut non couvert
 * y a des consequences legales, pas seulement fonctionnelles.
 */
const config: Config = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: { '^.+\\.ts$': ['ts-jest', { tsconfig: '<rootDir>/../tsconfig.json' }] },
  collectCoverageFrom: ['**/*.(t|j)s', '!**/*.module.ts', '!**/main.ts', '!**/*.dto.ts'],
  coverageDirectory: '../coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  testEnvironment: 'node',
  coverageThreshold: {
    global: { lines: 0, statements: 0, branches: 0, functions: 0 },
    './modules/m1-ingestion/': { lines: 0 },
    './modules/m4-producteurs/': { lines: 0 },
    './modules/m6-admin/': { lines: 0 },
  },
};

export default config;
