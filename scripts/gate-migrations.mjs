#!/usr/bin/env node
/**
 * PORTE : garde-fou des migrations de schema — ADR-027.
 *
 * Protege trois tables dont l'integrite est exigee par la loi ou par les
 * regles de gestion :
 *   - evenement_audit   art. 32 Loi 2024/001, NFR-C3-05, ADR-009 du SDD
 *   - soumission_kobo   RG-M1-04 (conservation a vie de la reference d'origine)
 *   - version_fiche     ADR-006 du SDD, UC-M4-07, UC-M4-08
 *
 * Verifie en outre :
 *   - l'immuabilite des migrations deja appliquees (derive de checksum Prisma) ;
 *   - la retrocompatibilite exigee par le Blue-Green (ADR-032) ;
 *   - les operations posant un verrou exclusif en production (NFR-C2-01).
 */
import { join } from 'node:path';
import { existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { RACINE, echec, avertir, info, succes, conclure, fichiers, lire, lireJson, arguments_ } from './_lib.mjs';

const args = arguments_();
const DOSSIER = join(RACINE, 'apps/backend/prisma/migrations');
const CONFIG = join(RACINE, 'docs/regles-metier/tables-protegees.json');
const VERROU = join(DOSSIER, '..', 'migrations.lock');

const MARQUEUR_EXCEPTION = /--\s*CNIPAC-MIGRATION-EXCEPTION\s*:\s*(.+)/i;

if (!existsSync(DOSSIER)) {
  info('Aucun dossier de migrations : rien a verifier (socle Palier 0).');
  succes('Garde-fou migrations');
  process.exit(0);
}

const config = existsSync(CONFIG) ? lireJson(CONFIG) : { tables: [] };
const sqls = fichiers(DOSSIER, (f) => f.endsWith('.sql'));
info(`${sqls.length} fichier(s) de migration analyse(s).`);

// ---------------------------------------------------------------------------
// 1. Operations interdites sur les tables protegees.
// ---------------------------------------------------------------------------
for (const fichier of sqls) {
  const contenu = lire(fichier);
  const lignes = contenu.split('\n');
  const exception = contenu.match(MARQUEUR_EXCEPTION);

  for (const table of config.tables ?? []) {
    for (const motif of table.operations_interdites ?? []) {
      const regex = new RegExp(motif.replace('{table}', table.nom), 'i');
      lignes.forEach((ligne, i) => {
        if (ligne.trim().startsWith('--')) return;
        if (!regex.test(ligne)) return;

        const message =
          `Operation interdite sur la table protegee "${table.nom}" : ${ligne.trim().slice(0, 120)}\n` +
          `  Fondement : ${table.fondement}\n` +
          `  Une exception doit etre justifiee par un marqueur "-- CNIPAC-MIGRATION-EXCEPTION: <motif> / <ADR ou ticket>" ` +
          `et approuvee par un CODEOWNER de apps/backend/prisma/.`;

        if (exception) {
          avertir(`Exception de migration acceptee sur "${table.nom}" — justification : ${exception[1].trim()}`, fichier, i + 1);
        } else {
          echec(message, fichier, i + 1);
        }
      });
    }
  }
}

// ---------------------------------------------------------------------------
// 2. Immuabilite des migrations deja appliquees.
//    Prisma stocke un checksum ; modifier une migration appliquee bloque le
//    demarrage en PROD. Le defaut doit etre arrete ici.
// ---------------------------------------------------------------------------
if (existsSync(VERROU)) {
  const verrou = lireJson(VERROU);
  for (const [nom, empreinteAttendue] of Object.entries(verrou.migrations ?? {})) {
    const chemin = join(DOSSIER, nom, 'migration.sql');
    if (!existsSync(chemin)) {
      echec(
        `La migration deja appliquee "${nom}" a ete supprimee. Une migration appliquee est immuable : ` +
        `corriger par une NOUVELLE migration, jamais en editant l'ancienne.`,
        'apps/backend/prisma/migrations.lock',
      );
      continue;
    }
    const empreinte = createHash('sha256').update(lire(chemin)).digest('hex');
    if (empreinte !== empreinteAttendue) {
      echec(
        `La migration deja appliquee "${nom}" a ete modifiee (empreinte ${empreinte.slice(0, 12)} au lieu de ` +
        `${empreinteAttendue.slice(0, 12)}). Prisma refusera de demarrer en PREPROD et en PROD. ` +
        `Corriger par une nouvelle migration.`,
        `apps/backend/prisma/migrations/${nom}/migration.sql`,
      );
    }
  }
} else {
  info('migrations.lock absent : il sera cree a la premiere migration appliquee en PREPROD.');
}

// ---------------------------------------------------------------------------
// 3. Retrocompatibilite — prerequis du Blue-Green (ADR-032).
//    Pendant la bascule, Blue et Green partagent la meme base.
// ---------------------------------------------------------------------------
if (args.retrocompatibilite) {
  const RUPTURES = [
    { motif: /DROP\s+COLUMN/i, libelle: 'suppression de colonne' },
    { motif: /RENAME\s+(COLUMN|TO)/i, libelle: 'renommage' },
    { motif: /ALTER\s+COLUMN\s+\S+\s+SET\s+NOT\s+NULL/i, libelle: 'passage a NOT NULL' },
    { motif: /ALTER\s+COLUMN\s+\S+\s+TYPE/i, libelle: 'changement de type' },
    { motif: /DROP\s+TABLE/i, libelle: 'suppression de table' },
  ];
  for (const fichier of sqls) {
    const contenu = lire(fichier);
    if (MARQUEUR_EXCEPTION.test(contenu)) continue;
    contenu.split('\n').forEach((ligne, i) => {
      if (ligne.trim().startsWith('--')) return;
      for (const { motif, libelle } of RUPTURES) {
        if (motif.test(ligne)) {
          echec(
            `Migration non retrocompatible (${libelle}) : ${ligne.trim().slice(0, 100)}\n` +
            `  Le deploiement Blue-Green (ADR-032) fait cohabiter l'ancienne et la nouvelle version ` +
            `sur la meme base. Proceder en deux temps : ajouter d'abord, retirer dans une release ulterieure. ` +
            `Voir docs/conventions/MIGRATIONS.md.`,
            fichier, i + 1,
          );
        }
      }
    });
  }
}

// ---------------------------------------------------------------------------
// 4. Operations posant un verrou exclusif — avertissement (NFR-C2-01).
// ---------------------------------------------------------------------------
for (const fichier of sqls) {
  lire(fichier).split('\n').forEach((ligne, i) => {
    if (ligne.trim().startsWith('--')) return;
    if (/CREATE\s+(UNIQUE\s+)?INDEX(?!\s+CONCURRENTLY)/i.test(ligne)) {
      avertir(
        `CREATE INDEX sans CONCURRENTLY : verrou exclusif pendant la construction. ` +
        `Sur une table volumineuse, cela provoque une indisponibilite (NFR-C2-01, 99,5 %). ` +
        `Justifier dans la PR ou utiliser CONCURRENTLY.`,
        fichier, i + 1,
      );
    }
    if (/ADD\s+COLUMN\s+\S+\s+[^;]*NOT\s+NULL(?![^;]*DEFAULT)/i.test(ligne)) {
      avertir(
        `ADD COLUMN NOT NULL sans DEFAULT : reecriture complete de la table sous verrou exclusif. ` +
        `Ajouter un DEFAULT, ou proceder en trois etapes.`,
        fichier, i + 1,
      );
    }
  });
}

conclure('Garde-fou migrations');
