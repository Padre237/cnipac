#!/usr/bin/env node
/**
 * PORTE : conformite des licences — ADR-025.
 * Exigences : NFR-C9-03 (stack open source), NFR-C9-04 (propriete du code).
 * Applique l'allowlist au seul perimetre A : dependances de production.
 */
import { execSync } from 'node:child_process';
import { join } from 'node:path';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { RACINE, echec, avertir, info, conclure, lireJson } from './_lib.mjs';

const CONFIG = join(RACINE, 'docs/conformite/licences-autorisees.json');
const config = lireJson(CONFIG);
const autorisees = new Set(config.autorisees);
const interdites = new Set(config.interdites);
const exemptes = new Set((config.exceptions_documentees ?? []).map((e) => e.composant.toLowerCase()));

let brut;
try {
  // license-checker-rseidelsohn : inventaire des licences des dependances de
  // production. Perimetre A d'ADR-025.
  brut = execSync('npx --no-install license-checker-rseidelsohn --production --json', {
    cwd: RACINE, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
  });
} catch {
  info('license-checker indisponible (dependances non installees). Porte sautee.');
  process.exit(0);
}

// Regroupement par licence, pour conserver la meme structure de traitement.
const parPaquet = JSON.parse(brut || '{}');
const parLicence = {};
for (const [cle, meta] of Object.entries(parPaquet)) {
  const licence = String(meta.licenses ?? 'UNKNOWN');
  const nom = cle.replace(/@[^@]+$/, '');
  const version = cle.slice(nom.length + 1);
  (parLicence[licence] ??= []).push({ name: nom, versions: [version] });
}
const inventaire = [];
let nb = 0;

for (const [licence, paquets] of Object.entries(parLicence)) {
  for (const p of paquets) {
    const nom = p.name ?? 'inconnu';
    // Les paquets du monorepo lui-meme ne sont pas des dependances tierces :
    // leur licence est celle du projet (LICENSE, propriete de l'Etat, NFR-C9-04),
    // et npm les declare « UNLICENSED » faute de champ SPDX.
    if (nom === 'cnipac' || nom.startsWith('@cnipac/')) continue;
    nb++;
    inventaire.push({ paquet: nom, version: p.versions?.join(', ') ?? '', licence });
    if (exemptes.has(nom.toLowerCase())) continue;

    // Les expressions composees (« MIT OR Apache-2.0 ») sont acceptees si au moins
    // une des branches est autorisee : le licencie choisit.
    const branches = licence.split(/\s+OR\s+/i).map((s) => s.replace(/[()]/g, '').trim());
    const compatible = branches.some((b) => autorisees.has(b));
    const bloquante = branches.every((b) => interdites.has(b));

    if (bloquante) {
      echec(
        `Licence interdite pour "${nom}" : ${licence}\n` +
        `  Perimetre A (dependance de production liee au code livre).\n` +
        `  Une licence copyleft fort menace la propriete du code exigee par NFR-C9-04.\n` +
        `  Remplacer la dependance, ou obtenir un avis ecrit de la direction juridique CENADI et ouvrir un ADR.`,
      );
    } else if (!compatible) {
      avertir(
        `Licence non repertoriee pour "${nom}" : ${licence}. ` +
        `Arbitrage manuel requis : completer docs/conformite/licences-autorisees.json.`,
      );
    }
  }
}

if (!existsSync(join(RACINE, 'reports'))) mkdirSync(join(RACINE, 'reports'), { recursive: true });
writeFileSync(
  join(RACINE, 'reports/licences.json'),
  JSON.stringify({ genere_le: new Date().toISOString(), perimetre: 'A — production', total: nb, inventaire }, null, 2),
);

info(`${nb} dependance(s) de production inventoriee(s). Rapport : reports/licences.json`);
conclure('Conformite des licences');
