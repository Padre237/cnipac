#!/usr/bin/env node
/**
 * PORTE : aucune donnee reelle dans les jeux de test versionnes — ADR-034.
 * Exigences : NFR-C4-01 (donnees nominatives non exposees), NFR-C9-02.
 *
 * Les coordonnees d'organismes publics (ministeres, conseils regionaux) sont
 * des donnees publiques et sont legitimes. Ce qui est interdit, ce sont les
 * donnees nominatives de personnes physiques.
 */
import { join } from 'node:path';
import { RACINE, echec, avertir, info, conclure, fichiers, lire } from './_lib.mjs';

// Domaines de test autorises pour les adresses electroniques synthetiques.
const DOMAINES_TEST = /@(test\.cnipac\.cm|example\.(com|org)|localhost)/i;

const MOTIFS = [
  {
    nom: 'adresse electronique reelle',
    regex: /[\w.+-]+@[\w-]+\.(cm|com|org|net|fr|gov)\b/gi,
    exclure: DOMAINES_TEST,
    message: 'Une adresse electronique hors domaine de test figure dans un jeu de donnees versionne.',
  },
  {
    nom: 'numero de telephone camerounais',
    // Plage reservee aux jeux de test : +237 6 99 00 XX XX (documentee dans jeux-de-donnees.md)
    regex: /\+?237\s?[62]\d{2}\s?\d{2}\s?\d{2}\s?\d{2}/g,
    exclure: /\+?237\s?699\s?00/,
    message: 'Un numero de telephone hors plage de test figure dans un jeu de donnees versionne.',
  },
];

const cibles = [
  ...fichiers(join(RACINE, 'infra/postgres/seed'), (f) => /\.(sql|json|csv)$/.test(f)),
  ...fichiers(join(RACINE, 'tests'), (f) => /\.(json|csv|sql)$/.test(f)),
  ...fichiers(join(RACINE, 'apps/backend/prisma'), (f) => /seed|fixture/i.test(f)),
];

for (const fichier of cibles) {
  const contenu = lire(fichier);
  for (const motif of MOTIFS) {
    for (const trouve of contenu.match(motif.regex) ?? []) {
      if (motif.exclure?.test(trouve)) continue;
      echec(
        `${motif.message}\n  Valeur detectee : ${trouve}\n` +
        `  ADR-034 : les donnees nominatives des jeux de test sont integralement synthetiques. ` +
        `Voir docs/regles-metier/jeux-de-donnees.md pour les plages reservees.`,
        fichier,
      );
    }
  }
}

// Un dump de production ne doit jamais entrer dans le depot.
for (const f of fichiers(RACINE, (x) => /\.(dump|backup)$/.test(x) || /\.sql\.gz$/.test(x))) {
  echec(`Sauvegarde de base de donnees versionnee : ${f}. Interdit par ADR-034 et le .gitignore.`, f);
}

info(`${cibles.length} fichier(s) de jeu de donnees controle(s).`);
conclure('Absence de donnees reelles');
