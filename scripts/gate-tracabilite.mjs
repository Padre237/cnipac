#!/usr/bin/env node
/**
 * PORTE : tracabilite exigences <-> tests — ADR-035.
 * Fondement : SRS chap. 15, SDD chap. 30 (« toute exigence est testable »,
 * « aucun element ne doit demeurer orphelin »).
 *
 * Verifications :
 *   1. aucun test ne reference un identifiant absent du registre (faute de frappe) ;
 *   2. toute regle de gestion RG-* possede un test unitaire dedie (ADR-028) ;
 *   3. toute exigence du palier courant est couverte (strict a la cloture du palier) ;
 *   4. tout article de loi couvert dispose d'au moins une exigence de rattachement.
 */
import { join } from 'node:path';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { RACINE, echec, avertir, info, conclure, fichiers, lire, lireJson, arguments_, palierCourant } from './_lib.mjs';

const args = arguments_();
const registre = lireJson(join(RACINE, 'docs/traceability/exigences.json'));
const palier = args.palier ?? palierCourant();
const strict = Boolean(args.strict);

const connues = new Map(registre.exigences.map((e) => [e.id, e]));
const MOTIF_ID = /\b((?:FR|NFR|RG|AC|UC)-(?:M[1-7]|C[1-9]|P[1-3]|TR)-\d{2})\b/g;

// ---------------------------------------------------------------------------
// Collecte des identifiants references par les tests.
// ---------------------------------------------------------------------------
const estTest = (f) =>
  /\.(spec|test|e2e)\.(ts|tsx|js|mjs)$/.test(f) ||
  (f.includes(`${'/'}tests${'/'}`) && /\.(ts|tsx|js|mjs)$/.test(f));

const fichiersTest = [
  ...fichiers(join(RACINE, 'apps'), estTest),
  ...fichiers(join(RACINE, 'packages'), estTest),
  ...fichiers(join(RACINE, 'tests'), estTest),
];

/** id -> { fichiers: Set, unitaire: bool, e2e: bool } */
const couverture = new Map();

for (const fichier of fichiersTest) {
  const contenu = lire(fichier);
  const estUnitaire = /\.(spec|test)\.(ts|tsx|js|mjs)$/.test(fichier) && !fichier.includes('/tests/e2e/');
  const estE2E = /\.e2e\./.test(fichier) || fichier.includes('/tests/e2e/');

  for (const [, id] of contenu.matchAll(MOTIF_ID)) {
    if (!connues.has(id)) {
      echec(
        `Le test reference l'identifiant "${id}", absent du registre des exigences.\n` +
        `  Soit il s'agit d'une faute de frappe, soit l'exigence doit etre declaree dans ` +
        `docs/traceability/exigences.json.`,
        fichier,
      );
      continue;
    }
    if (!couverture.has(id)) couverture.set(id, { fichiers: new Set(), unitaire: false, e2e: false });
    const c = couverture.get(id);
    c.fichiers.add(fichier.replace(RACINE + '/', ''));
    c.unitaire ||= estUnitaire;
    c.e2e ||= estE2E;
  }
}

info(`${fichiersTest.length} fichier(s) de test analyse(s) — ${couverture.size}/${connues.size} exigence(s) referencee(s).`);

// ---------------------------------------------------------------------------
// Regle 2 — toute regle de gestion a un test unitaire dedie.
// Les RG expriment l'invariant metier du systeme : elles sont pures et
// testables unitairement, sans exception possible.
// ---------------------------------------------------------------------------
const rgs = registre.exigences.filter((e) => e.type === 'RG');
const rgsNonCouvertes = [];
for (const rg of rgs) {
  const c = couverture.get(rg.id);
  if (!c || !c.unitaire) rgsNonCouvertes.push(rg.id);
}
if (rgsNonCouvertes.length) {
  const message =
    `${rgsNonCouvertes.length}/${rgs.length} regle(s) de gestion sans test unitaire dedie : ` +
    `${rgsNonCouvertes.slice(0, 8).join(', ')}${rgsNonCouvertes.length > 8 ? ', ...' : ''}\n` +
    `  Chaque RG doit avoir un test dont le nom porte son identifiant, ` +
    `ex. it('[RG-M1-02] le code unique genere n est jamais modifiable', ...).`;
  if (palier === 'P0') avertir(`${message}\n  (non bloquant au Palier 0 : les modules ne sont pas encore implementes)`);
  else echec(message);
}

// ---------------------------------------------------------------------------
// Regle 3 — exigences du palier courant.
// ---------------------------------------------------------------------------
const duPalier = registre.exigences.filter(
  (e) => (e.palier === palier || (e.type === 'AC' && e.palier === palier)) && e.type !== 'LOI',
);
const orphelines = duPalier.filter((e) => !couverture.has(e.id));
if (orphelines.length) {
  const message =
    `${orphelines.length}/${duPalier.length} exigence(s) du palier ${palier} sans test : ` +
    `${orphelines.slice(0, 10).map((e) => e.id).join(', ')}${orphelines.length > 10 ? ', ...' : ''}`;
  if (strict) echec(message);
  else avertir(`${message}\n  (bloquant a la cloture du palier ${palier})`);
}

// ---------------------------------------------------------------------------
// Regle 4 — chaque article de loi couvert a au moins une exigence rattachee.
// C'est le lien de conformite legale du SRS chap. 15.
// ---------------------------------------------------------------------------
const lois = registre.exigences.filter((e) => e.type === 'LOI');
for (const loi of lois) {
  const rattachees = registre.exigences.filter(
    (e) => Array.isArray(e.articles_loi) && e.articles_loi.includes(loi.article),
  );
  if (rattachees.length === 0) {
    avertir(
      `L'article "${loi.article}" (${loi.libelle}) n'a aucune exigence de rattachement declaree. ` +
      `Completer le champ "articles_loi" des exigences concernees (SRS chap. 15).`,
    );
  }
}

// ---------------------------------------------------------------------------
// Rapport de couverture, exploite par la matrice et le rapport de conformite.
// ---------------------------------------------------------------------------
const parType = {};
for (const e of registre.exigences) {
  parType[e.type] ??= { total: 0, couvertes: 0 };
  parType[e.type].total++;
  if (couverture.has(e.id)) parType[e.type].couvertes++;
}

if (!existsSync(join(RACINE, 'docs/traceability'))) mkdirSync(join(RACINE, 'docs/traceability'), { recursive: true });
writeFileSync(
  join(RACINE, 'docs/traceability/couverture.json'),
  JSON.stringify(
    {
      genere_le: new Date().toISOString(),
      palier,
      par_type: parType,
      detail: Object.fromEntries([...couverture].map(([id, c]) => [id, { ...c, fichiers: [...c.fichiers] }])),
    },
    null,
    2,
  ),
);

if (args.rapport) {
  console.log('\nCouverture par type :');
  for (const [type, s] of Object.entries(parType)) {
    const pct = s.total ? Math.round((s.couvertes / s.total) * 100) : 0;
    console.log(`  ${type.padEnd(4)} ${String(s.couvertes).padStart(3)}/${String(s.total).padEnd(3)}  ${pct}%`);
  }
}

conclure('Tracabilite des exigences');
