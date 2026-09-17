#!/usr/bin/env node
/**
 * PORTE : seuils et non-regression de couverture — ADR-026, ADR-028.
 * Exigence : NFR-C6-01. Remplace Codecov sans service externe.
 */
import { join } from 'node:path';
import { existsSync, writeFileSync, mkdirSync } from 'node:fs';
import { RACINE, echec, avertir, info, conclure, lire, lireJson, arguments_, palierCourant } from './_lib.mjs';

const args = arguments_();
const palier = palierCourant();
const config = lireJson(join(RACINE, 'docs/regles-metier/palier-courant.json'));
const seuils = config.seuils_couverture[palier];
const regressionMax = config.regression_max_points ?? 0.5;

/** Agrege un rapport LCOV par prefixe de chemin. */
function lireLcov(chemin) {
  if (!existsSync(chemin)) return null;
  const parFichier = [];
  let courant = null;
  for (const ligne of lire(chemin).split('\n')) {
    if (ligne.startsWith('SF:')) courant = { fichier: ligne.slice(3), trouvees: 0, couvertes: 0 };
    else if (ligne.startsWith('LF:') && courant) courant.trouvees = Number(ligne.slice(3));
    else if (ligne.startsWith('LH:') && courant) courant.couvertes = Number(ligne.slice(3));
    else if (ligne.startsWith('end_of_record') && courant) { parFichier.push(courant); courant = null; }
  }
  return parFichier;
}

function pourcentage(fichiers) {
  const t = fichiers.reduce((s, f) => s + f.trouvees, 0);
  const c = fichiers.reduce((s, f) => s + f.couvertes, 0);
  return t === 0 ? 100 : (c / t) * 100;
}

const sources = [
  { cle: 'backend_global', lcov: 'apps/backend/coverage/lcov.info', filtre: () => true },
  { cle: 'm1', lcov: 'apps/backend/coverage/lcov.info', filtre: (f) => f.includes('m1-ingestion') },
  { cle: 'm4', lcov: 'apps/backend/coverage/lcov.info', filtre: (f) => f.includes('m4-producteurs') },
  { cle: 'm6', lcov: 'apps/backend/coverage/lcov.info', filtre: (f) => f.includes('m6-admin') },
  { cle: 'shared_types', lcov: 'packages/shared-types/coverage/lcov.info', filtre: () => true },
  { cle: 'frontend_global', lcov: 'apps/frontend/coverage/lcov.info', filtre: () => true },
  { cle: 'frontend_shared', lcov: 'apps/frontend/coverage/lcov.info', filtre: (f) => f.includes('/shared/') },
];

const mesures = {};
let rapportTrouve = false;

for (const { cle, lcov, filtre } of sources) {
  const seuil = seuils?.[cle];
  if (seuil === undefined) continue;
  const donnees = lireLcov(join(RACINE, lcov));
  if (!donnees) continue;
  rapportTrouve = true;
  const retenus = donnees.filter((d) => filtre(d.fichier));
  if (!retenus.length) continue;
  const pct = pourcentage(retenus);
  mesures[cle] = Number(pct.toFixed(2));
  const symbole = pct >= seuil ? 'OK  ' : 'ECHEC';
  info(`${symbole} ${cle.padEnd(18)} ${pct.toFixed(1).padStart(6)} %  (seuil ${palier} : ${seuil} %)`);
  if (pct < seuil) {
    echec(
      `Couverture insuffisante sur "${cle}" : ${pct.toFixed(1)} % < ${seuil} % exige au palier ${palier}.\n` +
      `  Fondement : NFR-C6-01 et ADR-028. Les modules M1, M4 et M6 ont un seuil renforce ` +
      `car un defaut non couvert y a des consequences legales.`,
    );
  }
}

if (!rapportTrouve) {
  info('Aucun rapport lcov.info trouve : executer les tests avec --coverage. Porte sautee.');
  process.exit(0);
}

// Non-regression par rapport a la reference.
const refChemin = join(RACINE, 'docs/traceability/couverture-reference.json');
if (existsSync(refChemin)) {
  const ref = lireJson(refChemin);
  for (const [cle, valeur] of Object.entries(mesures)) {
    const precedent = ref.mesures?.[cle];
    if (precedent === undefined) continue;
    const delta = valeur - precedent;
    if (delta < -regressionMax) {
      echec(
        `Regression de couverture sur "${cle}" : ${precedent} % -> ${valeur} % (${delta.toFixed(2)} pt).\n` +
        `  Tolerance : ${regressionMax} pt. Ajouter des tests, ou justifier explicitement dans la PR.`,
      );
    } else if (delta < 0) {
      avertir(`Leger recul sur "${cle}" : ${delta.toFixed(2)} pt (dans la tolerance).`);
    }
  }
}

if (!existsSync(join(RACINE, 'reports'))) mkdirSync(join(RACINE, 'reports'), { recursive: true });
writeFileSync(join(RACINE, 'reports/couverture.json'), JSON.stringify({ palier, mesures, mesure_le: new Date().toISOString() }, null, 2));

if (process.env.GITHUB_STEP_SUMMARY) {
  const { appendFileSync } = await import('node:fs');
  const lignes = Object.entries(mesures).map(([k, v]) => `| ${k} | ${v} % | ${seuils[k]} % |`).join('\n');
  appendFileSync(process.env.GITHUB_STEP_SUMMARY, `### Couverture — palier ${palier}\n\n| Perimetre | Mesure | Seuil |\n|---|---|---|\n${lignes}\n`);
}

conclure('Couverture de code');
