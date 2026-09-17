#!/usr/bin/env node
/**
 * PORTE : contrastes du design system — ADR-030.
 * Exigence : NFR-C7-03 (4,5:1 texte normal, 3:1 texte large).
 *
 * Verifie les JETONS de couleur, en amont de leur usage dans les composants :
 * une couleur non conforme est rejetee avant qu'un ecran ne soit implemente
 * avec, ce qui evite la reprise de maquettes.
 */
import { join } from 'node:path';
import { existsSync } from 'node:fs';
import { RACINE, echec, info, conclure, lireJson } from './_lib.mjs';

const JETONS = join(RACINE, 'packages/shared-types/src/design-tokens.json');
if (!existsSync(JETONS)) {
  info('design-tokens.json absent (design system non encore importe). Porte sautee.');
  process.exit(0);
}

const hexVersRgb = (h) => {
  const v = h.replace('#', '');
  const n = v.length === 3 ? v.split('').map((c) => c + c).join('') : v;
  return [0, 2, 4].map((i) => parseInt(n.slice(i, i + 2), 16));
};

// WCAG 2.1 — luminance relative.
const luminance = (rgb) => {
  const [r, g, b] = rgb.map((c) => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};

const ratio = (a, b) => {
  const [l1, l2] = [luminance(hexVersRgb(a)), luminance(hexVersRgb(b))].sort((x, y) => y - x);
  return (l1 + 0.05) / (l2 + 0.05);
};

const { paires_a_verifier: paires = [] } = lireJson(JETONS);
for (const paire of paires) {
  const r = ratio(paire.premier_plan, paire.arriere_plan);
  const seuil = paire.texte_large ? 3 : 4.5;
  const verdict = r >= seuil ? 'OK  ' : 'ECHEC';
  info(`${verdict} ${paire.nom.padEnd(34)} ${r.toFixed(2)}:1  (seuil ${seuil}:1)`);
  if (r < seuil) {
    echec(
      `Contraste insuffisant pour "${paire.nom}" : ${r.toFixed(2)}:1 < ${seuil}:1 ` +
      `(${paire.premier_plan} sur ${paire.arriere_plan}).\n` +
      `  NFR-C7-03 impose 4,5:1 pour le texte normal et 3:1 pour le texte large. ` +
      `Corriger le jeton dans le design system, pas dans le composant.`,
      'packages/shared-types/src/design-tokens.json',
    );
  }
}

info(`${paires.length} paire(s) de couleurs verifiee(s).`);
conclure('Contrastes WCAG');
