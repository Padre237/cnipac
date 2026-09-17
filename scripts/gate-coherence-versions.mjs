#!/usr/bin/env node
/**
 * PORTE : coherence des versions de runtime — ADR-017.
 * La version de Node est declaree en trois endroits ; ils doivent concorder,
 * faute de quoi la CI, le poste developpeur et la production divergent.
 */
import { join } from 'node:path';
import { existsSync } from 'node:fs';
import { RACINE, echec, info, conclure, lire, lireJson, fichiers } from './_lib.mjs';

const MAJEURE_ATTENDUE = '22';   // SDD §4.2 : « Node.js LTS — 20.x ou 22.x »

// .nvmrc
const nvmrc = join(RACINE, '.nvmrc');
if (!existsSync(nvmrc)) {
  echec('.nvmrc absent : la version de Node n est pas epinglee pour les postes developpeurs (ADR-017).');
} else {
  const v = lire(nvmrc).trim();
  if (!v.startsWith(MAJEURE_ATTENDUE)) {
    echec(`.nvmrc declare Node ${v}, or le projet retient Node ${MAJEURE_ATTENDUE} LTS (SDD §4.2).`, '.nvmrc');
  } else info(`.nvmrc : Node ${v}`);
}

// package.json engines
const pkg = lireJson(join(RACINE, 'package.json'));
const engines = pkg.engines?.node ?? '';
if (!engines.includes(MAJEURE_ATTENDUE)) {
  echec(`package.json engines.node = "${engines}" : incoherent avec Node ${MAJEURE_ATTENDUE} (SDD §4.2).`, 'package.json');
} else info(`package.json engines.node : ${engines}`);

// Workspaces npm (SDD §26.4)
if (!Array.isArray(pkg.workspaces) || pkg.workspaces.length === 0) {
  echec('package.json ne declare pas de champ "workspaces". Le monorepo npm ne peut pas resoudre les paquets internes.', 'package.json');
} else info(`package.json workspaces : ${pkg.workspaces.join(', ')}`);

// Dockerfiles
for (const df of fichiers(join(RACINE, 'infra/docker'), (f) => f.includes('Dockerfile'))) {
  const contenu = lire(df);
  for (const m of contenu.matchAll(/FROM\s+node:(\d+)[^\s]*/g)) {
    if (m[1] !== MAJEURE_ATTENDUE) {
      echec(`${df} utilise node:${m[1]} : incoherent avec Node ${MAJEURE_ATTENDUE} LTS (SDD §4.2).`, df);
    }
  }
}

conclure('Coherence des versions');
