#!/usr/bin/env node
/**
 * PORTE : regle d'affectation des runners — ADR-014.
 * Exigences : NFR-C9-01, NFR-C9-02 (aucune donnee reelle hors du territoire).
 *
 * Tout job qui touche un environnement reel, un secret de production ou un hote
 * CENADI doit s'executer sur un runner self-hosted. Sans exception.
 */
import { join } from 'node:path';
import { RACINE, echec, info, conclure, fichiers, lire } from './_lib.mjs';

const workflows = fichiers(join(RACINE, '.github/workflows'), (f) => f.endsWith('.yml'));

// Marqueurs revelant qu'un job manipule un environnement reel.
const MARQUEURS = [
  { motif: /environment:\s*\n?\s*(name:\s*)?(preprod|production)/i, libelle: 'declare un environnement PREPROD ou PRODUCTION' },
  { motif: /scripts\/deploy\.sh|scripts\/migrer\.sh|scripts\/restaurer\.sh/, libelle: 'execute un script de deploiement ou de restauration' },
  { motif: /preprod\.cnipac\.cm|https:\/\/cnipac\.cm/, libelle: 'cible un hote CENADI' },
  { motif: /secrets\.CNIPAC_SSH|secrets\.CNIPAC_PROD/, libelle: 'utilise un secret d infrastructure' },
];

for (const fichier of workflows) {
  const contenu = lire(fichier);
  // Decoupage grossier par job : suffisant et sans dependance externe.
  const blocs = contenu.split(/\n  (?=[a-z0-9_-]+:\n)/i);

  for (const bloc of blocs) {
    const nomJob = bloc.match(/^\s*([a-z0-9_-]+):/i)?.[1] ?? '?';
    const runsOn = bloc.match(/runs-on:\s*(.+)/)?.[1] ?? '';
    if (!runsOn) continue;

    const selfHosted = /self-hosted/.test(runsOn);
    const touche = MARQUEURS.find(({ motif }) => motif.test(bloc));

    if (touche && !selfHosted) {
      echec(
        `Job "${nomJob}" : ${touche.libelle}, mais s'execute sur un runner heberge (${runsOn.trim()}).\n` +
        `  ADR-014 impose un runner self-hosted CENADI pour tout job touchant un environnement reel.\n` +
        `  Forme attendue : runs-on: [self-hosted, cnipac, cenadi]`,
        fichier,
      );
    }
  }
}

info(`${workflows.length} workflow(s) analyse(s).`);
conclure('Regle d affectation des runners');
