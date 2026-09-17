import { defineConfig, devices } from '@playwright/test';

/**
 * Tests de bout en bout — ADR-007 du SDD, SDD §25.4 et §25.9.
 * Quatorze scénarios, dont les cinq parcours détaillés du §25.9.
 * NFR-C5-02 : Chrome, Firefox, Edge et Safari. Webkit couvre Safari.
 */
export default defineConfig({
  testDir: '.',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [['html', { outputFolder: '../../playwright-report' }], ['list'], ['json', { outputFile: '../../reports/e2e.json' }]],
  timeout: 45_000,
  use: {
    baseURL: process.env.CNIPAC_BASE_URL ?? 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    locale: 'fr-CM',
    timezoneId: 'Africa/Douala',   // NFR-C8-03
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    // NFR-C7-04 : résolution minimale supportée, 360×640.
    { name: 'mobile', use: { ...devices['Pixel 5'], viewport: { width: 360, height: 640 } } },
    // NFR-C1-01 : profil 3G de référence du SRS §2.4.2.
    { name: 'mobile-3g', use: { ...devices['Pixel 5'], launchOptions: { args: ['--force-effective-connection-type=3g'] } } },
  ],
});
