// Utilitaires communs aux portes de qualite CNIPAC.
import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

export const RACINE = join(fileURLToPath(import.meta.url), '..', '..');

const COULEURS = { rouge: '\x1b[31m', vert: '\x1b[32m', jaune: '\x1b[33m', gris: '\x1b[90m', fin: '\x1b[0m' };
const enCI = process.env.GITHUB_ACTIONS === 'true';

export const erreurs = [];
export const avertissements = [];

export function echec(message, fichier, ligne) {
  erreurs.push({ message, fichier, ligne });
  if (enCI) {
    const loc = fichier ? `file=${fichier}${ligne ? `,line=${ligne}` : ''}` : '';
    console.log(`::error ${loc}::${message}`);
  } else {
    console.error(`${COULEURS.rouge}ERREUR${COULEURS.fin} ${message}${fichier ? ` ${COULEURS.gris}(${fichier}${ligne ? `:${ligne}` : ''})${COULEURS.fin}` : ''}`);
  }
}

export function avertir(message, fichier, ligne) {
  avertissements.push({ message, fichier, ligne });
  if (enCI) {
    const loc = fichier ? `file=${fichier}${ligne ? `,line=${ligne}` : ''}` : '';
    console.log(`::warning ${loc}::${message}`);
  } else {
    console.warn(`${COULEURS.jaune}ATTENTION${COULEURS.fin} ${message}${fichier ? ` ${COULEURS.gris}(${fichier})${COULEURS.fin}` : ''}`);
  }
}

export function info(message) {
  console.log(`${COULEURS.gris}${message}${COULEURS.fin}`);
}

export function succes(message) {
  console.log(`${COULEURS.vert}OK${COULEURS.fin} ${message}`);
}

/** Termine le processus selon le bilan. */
export function conclure(nomPorte) {
  console.log('');
  if (erreurs.length > 0) {
    console.log(`${COULEURS.rouge}${nomPorte} : ${erreurs.length} erreur(s), ${avertissements.length} avertissement(s).${COULEURS.fin}`);
    process.exit(1);
  }
  console.log(`${COULEURS.vert}${nomPorte} : conforme${COULEURS.fin}${avertissements.length ? ` (${avertissements.length} avertissement(s))` : ''}.`);
  process.exit(0);
}

/** Parcours recursif filtre. */
export function fichiers(racine, filtre, ignore = ['node_modules', '.git', 'dist', 'coverage', 'docs/design', 'docs/reference']) {
  const resultat = [];
  if (!existsSync(racine)) return resultat;
  (function parcourir(dir) {
    for (const entree of readdirSync(dir)) {
      const chemin = join(dir, entree);
      const rel = relative(RACINE, chemin).split('\\').join('/');
      // Comparaison par segment : ".github" ne doit pas etre exclu par ".git".
      if (ignore.some((i) => entree === i || rel === i || rel.startsWith(i + '/'))) continue;
      const st = statSync(chemin);
      if (st.isDirectory()) parcourir(chemin);
      else if (filtre(chemin)) resultat.push(chemin);
    }
  })(racine);
  return resultat;
}

export function lireJson(chemin) {
  return JSON.parse(readFileSync(chemin, 'utf8'));
}

export function lire(chemin) {
  return readFileSync(chemin, 'utf8');
}

export function arguments_() {
  const args = {};
  for (const a of process.argv.slice(2)) {
    const m = a.match(/^--([^=]+)(?:=(.*))?$/);
    if (m) args[m[1]] = m[2] ?? true;
  }
  return args;
}

/** Palier de livraison courant (P1/P2/P3) — ADR-028. */
export function palierCourant() {
  const chemin = join(RACINE, 'docs/regles-metier/palier-courant.json');
  if (!existsSync(chemin)) return 'P0';
  return lireJson(chemin).palier;
}
