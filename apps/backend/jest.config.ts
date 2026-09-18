import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Config } from 'jest';

/**
 * ADR-028 — seuils de couverture différenciés par module et par palier.
 *
 * Les seuils sont lus depuis docs/regles-metier/palier-courant.json : un seul
 * fichier à modifier au passage de jalon, et la configuration ne peut pas
 * diverger de la décision documentée.
 *
 * Les seuils PAR CHEMIN ne sont appliqués qu'à partir du moment où ils sont
 * non nuls : Jest échoue sur « Coverage data for ./modules/... was not found »
 * lorsqu'un chemin déclaré ne contient encore aucun code couvert — ce qui est
 * le cas des sept modules au Palier 0.
 */
interface PalierCourant {
  palier: string;
  seuils_couverture: Record<string, Record<string, number>>;
}

const racine = join(__dirname, '..', '..');
const config_palier = JSON.parse(
  readFileSync(join(racine, 'docs/regles-metier/palier-courant.json'), 'utf8'),
) as PalierCourant;

const seuils = config_palier.seuils_couverture[config_palier.palier] ?? {};

const seuils_par_module: Record<string, { lines: number }> = {};
for (const [chemin, cle] of [
  ['./modules/m1-ingestion/', 'm1'],
  ['./modules/m4-producteurs/', 'm4'],
  ['./modules/m6-admin/', 'm6'],
] as const) {
  const valeur = seuils[cle] ?? 0;
  if (valeur > 0) seuils_par_module[chemin] = { lines: valeur };
}

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
    global: {
      lines: seuils['backend_global'] ?? 0,
      statements: seuils['backend_global'] ?? 0,
      branches: 0,
      functions: 0,
    },
    ...seuils_par_module,
  },
};

export default config;
