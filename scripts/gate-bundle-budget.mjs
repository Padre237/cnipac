#!/usr/bin/env node
/**
 * PORTE : budget de bundle — ADR-029.
 * Exigences : NFR-C1-07 (<= 2 Mo gzip), NFR-C1-01 (carte <= 5 s en 3G), NFR-C1-06.
 * Budget applique : 1,6 Mo, soit 20 % de marge d'exploitation.
 */
import { join, basename } from 'node:path';
import { existsSync, statSync, readFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import { RACINE, echec, avertir, info, succes, conclure, fichiers, lireJson, arguments_ } from './_lib.mjs';

const args = arguments_();
const DIST = join(RACINE, 'apps/frontend/dist');
const config = lireJson(join(RACINE, 'docs/regles-metier/budget-bundle.json'));

if (!existsSync(DIST)) {
  info('apps/frontend/dist absent : lancer "pnpm --filter @cnipac/frontend build" avant cette porte.');
  process.exit(0);
}

const tailleGzip = (f) => gzipSync(readFileSync(f), { level: 9 }).length;
const ko = (n) => `${(n / 1024).toFixed(1)} ko`;

const assets = fichiers(DIST, () => true, []);
const js = assets.filter((f) => f.endsWith('.js'));
const css = assets.filter((f) => f.endsWith('.css'));
const polices = assets.filter((f) => /\.(woff2?|ttf|otf)$/.test(f));
const images = assets.filter((f) => /\.(png|jpe?g|gif|svg|webp|avif)$/.test(f));

// ---------------------------------------------------------------------------
// Entree : index + chunks charges au demarrage (non differes par React.lazy).
// ---------------------------------------------------------------------------
const index = join(DIST, 'index.html');
const html = existsSync(index) ? readFileSync(index, 'utf8') : '';
const critiques = js.filter((f) => html.includes(basename(f)));
const poidsEntree = [...critiques, ...css].reduce((s, f) => s + tailleGzip(f), 0);

const b = config.budgets.entree_totale;
info(`Entree (JS critique + CSS, gzip) : ${ko(poidsEntree)} — budget ${ko(b.max)}, exigence NFR-C1-07 a 2 048 ko.`);
if (poidsEntree > b.max) {
  echec(
    `Budget d'entree depasse : ${ko(poidsEntree)} > ${ko(b.max)}.\n` +
    `  NFR-C1-07 plafonne a 2 Mo gzip ; le budget applique conserve 20 % de marge (ADR-029).\n` +
    `  A 1 Mbit/s (3G de reference, SRS §2.4.2), ${ko(poidsEntree)} representent ` +
    `${(poidsEntree * 8 / 1_000_000).toFixed(1)} s de telechargement dans le cas ideal.`,
  );
} else if (poidsEntree > b.alerte) {
  avertir(`Entree a ${ko(poidsEntree)}, au-dessus du seuil d'alerte (${ko(b.alerte)}). Surveiller la tendance.`);
}

// ---------------------------------------------------------------------------
// Budgets par chunk differe.
// ---------------------------------------------------------------------------
for (const [cle, budget] of Object.entries(config.budgets)) {
  if (!cle.startsWith('chunk_')) continue;
  const nom = cle.replace('chunk_', '');
  const trouves = js.filter((f) => basename(f).toLowerCase().includes(nom.toLowerCase()));
  if (!trouves.length) continue;
  const poids = trouves.reduce((s, f) => s + tailleGzip(f), 0);
  info(`  chunk ${nom} : ${ko(poids)} (budget ${ko(budget.max)})`);
  if (poids > budget.max) {
    echec(`Chunk "${nom}" a ${ko(poids)}, budget ${ko(budget.max)} (${budget.exigence ?? 'ADR-029'}).`);
  }
}

// ---------------------------------------------------------------------------
// Regle de code-splitting opposable (SDD §20.3) : le code d'administration ne
// doit jamais etre telecharge par un visiteur anonyme de la carte publique.
// ---------------------------------------------------------------------------
for (const module of config.interdits_dans_entree.modules) {
  const marqueur = module.split('/').pop();
  const fautif = critiques.find((f) => readFileSync(f, 'utf8').includes(`${marqueur}/`));
  if (fautif) {
    echec(
      `Le module "${module}" apparait dans le chunk d'entree (${basename(fautif)}).\n` +
      `  SDD §20.3 : un utilisateur anonyme consultant la carte ne doit jamais telecharger ` +
      `le code d'administration. Verifier le React.lazy() de la route correspondante.`,
    );
  }
}

// ---------------------------------------------------------------------------
// Ressources statiques.
// ---------------------------------------------------------------------------
for (const img of images) {
  const t = statSync(img).size;
  if (t > config.budgets.image_unitaire.max) {
    echec(`Image "${basename(img)}" a ${ko(t)} (max ${ko(config.budgets.image_unitaire.max)}). Convertir en WebP.`);
  }
}
const poidsPolices = polices.reduce((s, f) => s + statSync(f).size, 0);
if (poidsPolices > config.budgets.polices_total.max) {
  echec(`Polices : ${ko(poidsPolices)} (max ${ko(config.budgets.polices_total.max)}). Sous-ensemble latin uniquement.`);
}

if (args['commentaire-pr'] && process.env.GITHUB_STEP_SUMMARY) {
  const { appendFileSync } = await import('node:fs');
  appendFileSync(
    process.env.GITHUB_STEP_SUMMARY,
    `### Budget de bundle (NFR-C1-07)\n\n` +
    `| Metrique | Mesure | Budget |\n|---|---|---|\n` +
    `| Entree gzip | ${ko(poidsEntree)} | ${ko(b.max)} |\n` +
    `| Polices | ${ko(poidsPolices)} | ${ko(config.budgets.polices_total.max)} |\n\n` +
    `Temps de telechargement estime a 1 Mbit/s : ${(poidsEntree * 8 / 1_000_000).toFixed(1)} s.\n`,
  );
}

succes(`${assets.length} artefact(s) analyse(s).`);
conclure('Budget de bundle');
