#!/usr/bin/env node
/**
 * PORTE : epinglage des images par digest — ADR-023.
 * Exigences : NFR-C5-05 (reconstruction a l'identique), parite PREPROD/PROD (SDD §8.1).
 * Un tag mobile rend ces deux proprietes invérifiables.
 */
import { join } from 'node:path';
import { RACINE, echec, avertir, info, conclure, fichiers, lire } from './_lib.mjs';

const cibles = [
  ...fichiers(join(RACINE, 'infra'), (f) => f.endsWith('.yml') || f.endsWith('.yaml') || f.includes('Dockerfile')),
  ...fichiers(join(RACINE, '.github/workflows'), (f) => f.endsWith('.yml')),
];

// Les images de la CI hebergee ne portent pas de donnees : avertissement seulement.
const TOLERE = [/\.github\/workflows\//];

// Les images PRODUITES PAR LE PROJET sont identifiees par leur tag semver, qui
// est lui-meme signe (SRS §14.8, ADR-024) : le tag EST la reference tracable.
// Les epingler par digest imposerait de modifier les fichiers Compose a chaque
// release, sans gain de tracabilite. Leur integrite est verifiee au deploiement
// par `cosign verify` (scripts/deploy.sh).
const IMAGES_DU_PROJET = /(^|\/)cnipac-(backend|frontend)$/;

let total = 0;
let epinglees = 0;

for (const fichier of cibles) {
  const lignes = lire(fichier).split('\n');

  // Etapes internes d'un Dockerfile multi-stage : `FROM deps AS builder` ne
  // reference pas un registre mais une etape declaree plus haut. Les collecter
  // d'abord, sinon la porte produit un faux positif sur chaque multi-stage.
  const etapesInternes = new Set(
    lignes.flatMap((l) => [...l.matchAll(/^\s*FROM\s+\S+\s+AS\s+([\w.-]+)/gi)].map((m) => m[1].toLowerCase())),
  );

  lignes.forEach((ligne, i) => {
    const t = ligne.trim();
    if (t.startsWith('#')) return;

    // Les images des Dockerfiles passent souvent par un ARG : il faut le
    // verifier lui aussi, sinon l'image de base echappe au controle.
    const argImage = t.match(/^ARG\s+\w*IMAGE\w*=([a-z0-9][\w.\-/]*(?::[\w.\-]+)?)(@sha256:[a-f0-9]{64})?\s*$/i);
    const m = argImage ?? t.match(/^(?:image:|FROM)\s+([a-z0-9][\w.\-/]*(?::[\w.\-]+)?)(@sha256:[a-f0-9]{64})?/i);
    if (!m) return;
    const [, reference, digest] = m;
    if (reference.startsWith('$') || reference.includes('${')) return;        // interpole au deploiement
    if (etapesInternes.has(reference.toLowerCase())) return;                  // etape multi-stage interne
    if (IMAGES_DU_PROJET.test(reference.split(':')[0])) return;               // image produite par le projet
    total++;
    if (digest) { epinglees++; return; }

    const message =
      `Image non epinglee par digest : "${reference}". ` +
      `Un tag mobile peut changer de contenu sans trace, ce qui rend NFR-C5-05 et la parite ` +
      `PREPROD/PROD invérifiables (ADR-023). Forme attendue : ${reference}@sha256:<digest>.`;

    if (TOLERE.some((r) => r.test(fichier))) avertir(message, fichier, i + 1);
    else echec(message, fichier, i + 1);
  });
}

// Les digests placeholder du socle Palier 0 doivent etre resolus au Sprint 1.
// Bloquant des que la cible est PREPROD ou PROD.
const PLACEHOLDER = /@sha256:0{64}/;
let placeholders = 0;
for (const fichier of cibles) {
  lire(fichier).split('\n').forEach((ligne, i) => {
    if (!PLACEHOLDER.test(ligne)) return;
    placeholders++;
    const message =
      `Digest placeholder non resolu : ${ligne.trim().slice(0, 90)}\n` +
      `  Executer scripts/resoudre-digests.sh (Sprint 1) avant tout deploiement.`;
    if (process.env.CNIPAC_ENV === 'preprod' || process.env.CNIPAC_ENV === 'prod') {
      echec(message, fichier, i + 1);
    } else {
      avertir(message, fichier, i + 1);
    }
  });
}

info(`${epinglees}/${total} image(s) epinglee(s) par digest${placeholders ? `, dont ${placeholders} placeholder(s) a resoudre` : ''}.`);
conclure('Epinglage des images');
