#!/usr/bin/env node
/**
 * Generation du SBOM CycloneDX — ADR-024.
 * Exigence : NFR-C9-03, dont le SDD §4.1 precise que la verification se fait
 * « par inspection des licences via SBOM ». Le SBOM est donc une piece de
 * conformite contractuelle, archivee par version dans docs/conformite/sbom/.
 */
import { execSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { RACINE, info, arguments_ } from './_lib.mjs';

const args = arguments_();
const version = args.version ?? process.env.CNIPAC_VERSION ?? 'dev';
const dossier = join(RACINE, 'docs/conformite/sbom', version);
mkdirSync(dossier, { recursive: true });

const cibles = [
  { nom: 'source', commande: `syft dir:${RACINE} -o cyclonedx-json` },
  { nom: 'backend', commande: `syft ${process.env.CNIPAC_REGISTRY ?? 'ghcr.io'}/${process.env.CNIPAC_IMAGE_PREFIX ?? 'cenadi-cm/cnipac'}-backend:${version} -o cyclonedx-json` },
  { nom: 'frontend', commande: `syft ${process.env.CNIPAC_REGISTRY ?? 'ghcr.io'}/${process.env.CNIPAC_IMAGE_PREFIX ?? 'cenadi-cm/cnipac'}-frontend:${version} -o cyclonedx-json` },
];

for (const cible of cibles) {
  const sortie = join(dossier, `sbom-${cible.nom}.cdx.json`);
  try {
    execSync(`${cible.commande} > "${sortie}"`, { stdio: ['ignore', 'pipe', 'inherit'], shell: '/bin/bash' });
    info(`SBOM ${cible.nom} : ${sortie}`);
  } catch {
    info(`SBOM ${cible.nom} non genere (syft absent ou image indisponible).`);
  }
}
