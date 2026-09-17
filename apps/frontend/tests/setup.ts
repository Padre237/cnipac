import '@testing-library/jest-dom/vitest';
import { expect } from 'vitest';
import * as matchers from 'vitest-axe/matchers';

/**
 * ADR-030 — l'accessibilite est bloquante des le niveau composant.
 * Toute violation axe-core de severite `critical` ou `serious` fait echouer le
 * test. Un nouveau composant sans test d'accessibilite n'est pas approuve en revue.
 *
 * Rappel : axe-core ne detecte automatiquement qu'environ 57 % des criteres
 * WCAG. L'audit manuel trimestriel (NVDA, VoiceOver) reste indispensable et
 * n'est pas rendu redondant par cette automatisation.
 */
expect.extend(matchers);
