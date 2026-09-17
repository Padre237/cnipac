#!/usr/bin/env node
/**
 * Genere docs/traceability/MATRICE.md — ADR-035.
 * La matrice est DERIVEE du registre et des tests : elle n'est jamais ecrite
 * a la main, ce qui est la seule facon qu'elle reste vraie (SRS chap. 15).
 */
import { join } from 'node:path';
import { writeFileSync, existsSync } from 'node:fs';
import { RACINE, info, lireJson, palierCourant } from './_lib.mjs';

const registre = lireJson(join(RACINE, 'docs/traceability/exigences.json'));
const cheminCouv = join(RACINE, 'docs/traceability/couverture.json');
const couverture = existsSync(cheminCouv) ? lireJson(cheminCouv).detail ?? {} : {};
const palier = palierCourant();

const etat = (id) => {
  const c = couverture[id];
  if (!c) return 'non couverte';
  const types = [c.unitaire && 'unitaire', c.e2e && 'E2E'].filter(Boolean).join(' + ');
  return `couverte (${types || 'test'})`;
};

const lignes = [];
lignes.push('# Matrice de tracabilite CNIPAC');
lignes.push('');
lignes.push('> **Document genere.** Ne pas modifier a la main — toute edition sera ecrasee');
lignes.push('> a la prochaine fusion sur `main`. La source est');
lignes.push('> [`exigences.json`](exigences.json) et les identifiants portes par les tests (ADR-035).');
lignes.push('');
lignes.push(`Genere le ${new Date().toISOString().slice(0, 10)} — palier courant : **${palier}**.`);
lignes.push('');

const parType = {};
for (const e of registre.exigences) {
  parType[e.type] ??= [];
  parType[e.type].push(e);
}

lignes.push('## Synthese');
lignes.push('');
lignes.push('| Type | Total | Couvertes | Taux |');
lignes.push('|---|---|---|---|');
for (const [type, liste] of Object.entries(parType)) {
  const n = liste.filter((e) => couverture[e.id]).length;
  lignes.push(`| ${type} | ${liste.length} | ${n} | ${Math.round((n / liste.length) * 100)} % |`);
}
lignes.push('');

const TITRES = {
  FR: 'Exigences fonctionnelles (SRS chap. 9)',
  NFR: 'Exigences non fonctionnelles (SRS chap. 10)',
  RG: 'Regles de gestion (SRS chap. 11)',
  UC: "Cas d'utilisation (SRS chap. 8)",
  AC: "Criteres d'acceptation (SRS chap. 14)",
  LOI: 'Conformite a la Loi n 2024/001 (SRS chap. 15)',
};

for (const [type, liste] of Object.entries(parType)) {
  lignes.push(`## ${TITRES[type] ?? type}`);
  lignes.push('');
  if (type === 'LOI') {
    lignes.push('| Article | Disposition | Exigences de couverture |');
    lignes.push('|---|---|---|');
    for (const e of liste) {
      lignes.push(`| ${e.article} | ${e.libelle} | ${(e.exigences_de_couverture ?? []).join(', ') || '—'} |`);
    }
  } else {
    lignes.push('| ID | Libelle | Palier | Articles de loi | Etat | Tests |');
    lignes.push('|---|---|---|---|---|---|');
    for (const e of liste.sort((a, b) => a.id.localeCompare(b.id))) {
      const c = couverture[e.id];
      const tests = c ? c.fichiers.slice(0, 3).map((f) => `\`${f.split('/').pop()}\``).join(', ') : '—';
      const libelle = (e.libelle ?? '').replace(/\|/g, '/').slice(0, 130);
      lignes.push(`| \`${e.id}\` | ${libelle} | ${e.palier ?? '—'} | ${(e.articles_loi ?? []).join(', ') || '—'} | ${etat(e.id)} | ${tests} |`);
    }
  }
  lignes.push('');
}

const sortie = join(RACINE, 'docs/traceability/MATRICE.md');
writeFileSync(sortie, lignes.join('\n'));
info(`Matrice ecrite : ${sortie} (${registre.exigences.length} exigences).`);
