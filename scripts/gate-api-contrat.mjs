#!/usr/bin/env node
/**
 * PORTE : non-regression du contrat d'API — ADR-037.
 * Exigences : FR-M7-08 (versionnage), FR-M7-04 (URI perennes), NFR-C5-01.
 *
 * L'API publique met en oeuvre l'article 26 de la Loi 2024/001 et sera consommee
 * par des tiers sur lesquels le CENADI n'a aucune visibilite. Une rupture de
 * contrat non versionnee casse leurs integrations sans preavis.
 */
import { join } from 'node:path';
import { existsSync, copyFileSync, mkdirSync } from 'node:fs';
import { RACINE, echec, avertir, info, conclure, lireJson } from './_lib.mjs';

const COURANT = join(RACINE, 'docs/api/openapi.json');
const REFERENCE = join(RACINE, 'docs/api/openapi.reference.json');

if (!existsSync(COURANT)) {
  info('Specification OpenAPI absente : lancer "pnpm --filter @cnipac/backend openapi:generate".');
  process.exit(0);
}
if (!existsSync(REFERENCE)) {
  mkdirSync(join(RACINE, 'docs/api'), { recursive: true });
  copyFileSync(COURANT, REFERENCE);
  info('Premiere execution : specification de reference initialisee.');
  process.exit(0);
}

const courant = lireJson(COURANT);
const reference = lireJson(REFERENCE);

const cheminsRef = Object.keys(reference.paths ?? {});
const cheminsCourant = new Set(Object.keys(courant.paths ?? {}));

// --- Rupture 1 : suppression d'un point d'entree -----------------------------
for (const chemin of cheminsRef) {
  if (cheminsCourant.has(chemin)) continue;
  const version = chemin.match(/\/api\/(v\d+)\//)?.[1];
  echec(
    `Point d'entree supprime : ${chemin}\n` +
    `  Rupture de contrat. ADR-037 : creer ${version ? version.replace(/\d+/, (n) => String(Number(n) + 1)) : 'une nouvelle version'} ` +
    `et maintenir ${version ?? 'la version actuelle'} pendant 12 mois minimum, avec en-tetes Deprecation et Sunset.`,
  );
}

// --- Rupture 2 : suppression d'une methode sur un chemin conserve ------------
for (const [chemin, operationsRef] of Object.entries(reference.paths ?? {})) {
  const operationsCourant = courant.paths?.[chemin];
  if (!operationsCourant) continue;
  for (const methode of Object.keys(operationsRef)) {
    if (!operationsCourant[methode]) {
      echec(`Methode ${methode.toUpperCase()} supprimee sur ${chemin} : rupture de contrat (ADR-037).`);
    }
  }
}

// --- Rupture 3 : un parametre optionnel devient obligatoire ------------------
for (const [chemin, operationsRef] of Object.entries(reference.paths ?? {})) {
  for (const [methode, opRef] of Object.entries(operationsRef)) {
    const opCourant = courant.paths?.[chemin]?.[methode];
    if (!opCourant) continue;
    for (const paramCourant of opCourant.parameters ?? []) {
      if (!paramCourant.required) continue;
      const paramRef = (opRef.parameters ?? []).find((p) => p.name === paramCourant.name);
      if (paramRef && !paramRef.required) {
        echec(`Parametre "${paramCourant.name}" devenu obligatoire sur ${methode.toUpperCase()} ${chemin} : rupture de contrat.`);
      }
      if (!paramRef) {
        echec(`Nouveau parametre obligatoire "${paramCourant.name}" sur ${methode.toUpperCase()} ${chemin} : rupture de contrat.`);
      }
    }
  }
}

// --- FR-M7-04 : aucun identifiant technique interne exposé -------------------
const specTexte = JSON.stringify(courant);
if (/"(id|_id|uuid_interne|rowid)"\s*:\s*\{[^}]*"format"\s*:\s*"int/i.test(specTexte)) {
  avertir(
    "Un identifiant numerique interne semble expose dans la specification publique. " +
    "FR-M7-04 et RG-M1-02 : l'identifiant public d'un producteur est son code unique perenne " +
    "CMR-<RESEAU>-<MIN>-<STRUCT>-<SEQ>, jamais une cle technique sequentielle.",
  );
}

info(`${cheminsCourant.size} point(s) d'entree dans la specification courante.`);
conclure("Contrat d'API");
