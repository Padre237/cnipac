#!/usr/bin/env node
/**
 * PORTE : aucun secret lu depuis une variable d'environnement — ADR-033.
 * Exigence : NFR-C3-02.
 * Une variable d'environnement apparait dans `docker inspect`, dans
 * /proc/<pid>/environ et dans les traces d'erreur. Les secrets se lisent
 * exclusivement par fichier (convention *_FILE, Docker secrets).
 */
import { join } from 'node:path';
import { RACINE, echec, info, conclure, fichiers, lire } from './_lib.mjs';

const SENSIBLE = /process\.env\.([A-Z0-9_]*(SECRET|PASSWORD|PASSWD|TOKEN|PRIVATE_KEY|APIKEY|API_KEY)[A-Z0-9_]*)/g;
// Exceptions legitimes : la variable *_FILE porte un chemin, pas un secret.
const AUTORISE = /_FILE$/;
// Les fichiers de test et de configuration locale sont hors perimetre.
const HORS_PERIMETRE = /\.(spec|test|e2e)\.|\/tests?\/|\.config\.|\/scripts\//;

const sources = [
  ...fichiers(join(RACINE, 'apps'), (f) => /\.(ts|tsx|js|mjs)$/.test(f)),
  ...fichiers(join(RACINE, 'packages'), (f) => /\.(ts|tsx|js|mjs)$/.test(f)),
];

let controles = 0;
for (const fichier of sources) {
  if (HORS_PERIMETRE.test(fichier)) continue;
  controles++;
  const contenu = lire(fichier);
  contenu.split('\n').forEach((ligne, i) => {
    for (const [, nom] of ligne.matchAll(SENSIBLE)) {
      if (AUTORISE.test(nom)) continue;
      echec(
        `Lecture d'un secret depuis une variable d'environnement : process.env.${nom}\n` +
        `  ADR-033 : les secrets se lisent par fichier. Utiliser process.env.${nom}_FILE ` +
        `et le chargeur commun (apps/backend/src/common/config/chargeur-secrets.ts).\n` +
        `  Motif : une variable d'environnement est exposee par docker inspect, /proc et les traces d'erreur.`,
        fichier, i + 1,
      );
    }
  });
}

info(`${controles} fichier(s) source controle(s).`);
conclure('Lecture des secrets');
