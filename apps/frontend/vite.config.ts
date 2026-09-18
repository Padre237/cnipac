import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'node:path';

/**
 * Construction du frontend CNIPAC.
 *
 * Deux contraintes gouvernent cette configuration :
 *   - NFR-C1-07 : bundle initial <= 2 Mo gzip (budget applique : 1,6 Mo, ADR-029) ;
 *   - SDD §20.3 : aucune route administrative dans le chunk d'entree.
 * Les deux sont verifiees en CI par scripts/gate-bundle-budget.mjs.
 */
export default defineConfig({
  plugins: [react()],
  resolve: { alias: { '@': resolve(__dirname, 'src') } },
  build: {
    target: 'es2022',
    sourcemap: true, // indispensable au diagnostic d'erreurs en production
    chunkSizeWarningLimit: 600,
    rollupOptions: {
      output: {
        // Decoupage explicite : les dependances lourdes sont isolees pour ne
        // jamais alourdir l'entree. Leaflet et Recharts representent l'essentiel
        // du poids de l'application.
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-carto': ['leaflet', 'react-leaflet'],
          'vendor-charts': ['recharts'],
          'vendor-data': ['@tanstack/react-query', 'zustand'],
          'vendor-i18n': ['i18next', 'react-i18next'],
        },
      },
    },
  },
  server: {
    port: 5173,
    proxy: { '/api': { target: 'http://localhost:3000', changeOrigin: true } },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.spec.{ts,tsx}', 'src/main.tsx', 'src/i18n/**'],
      // ADR-028 : seuils du palier courant. Releves a chaque jalon.
      thresholds: { lines: 0, functions: 0, branches: 0, statements: 0 },
    },
  },
});
