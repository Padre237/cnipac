/**
 * Tests des regles de gestion — SRS chapitre 11.
 *
 * CONVENTION OPPOSABLE (ADR-035) : le nom de chaque test porte entre crochets
 * l'identifiant de l'exigence qu'il couvre. scripts/gate-tracabilite.mjs echoue
 * si une regle de gestion n'a aucun test portant son identifiant, et si un test
 * reference un identifiant absent du registre.
 */
import { describe, it, expect } from 'vitest';
import {
  agregatPubliable,
  cleDeDoublon,
  codeProducteurValide,
  coordonneesDansEnveloppeCameroun,
  extractionDoitEtreTracee,
  indiceMaturiteArchivistique,
  transitionAutorisee,
  visibleSurCartePublique,
} from './regles-metier.js';
import {
  PONDERATION_MATURITE,
  RESEAUX_ARCHIVISTIQUES,
  REGIONS,
  ROLES,
  STATUTS_FICHE,
  TRANSITIONS_AUTORISEES,
} from './enumerations.js';

describe('Module M1 — ingestion', () => {
  it("[RG-M1-05] l'automate de statuts autorise la sequence nominale", () => {
    expect(transitionAutorisee('NOUVELLE', 'QUARANTAINE')).toBe(true);
    expect(transitionAutorisee('QUARANTAINE', 'VALIDEE')).toBe(true);
    expect(transitionAutorisee('VALIDEE', 'EDITEE')).toBe(true);
    expect(transitionAutorisee('EDITEE', 'ARCHIVEE')).toBe(true);
  });

  it("[RG-M1-05] aucune transition arriere n'est autorisee", () => {
    expect(transitionAutorisee('VALIDEE', 'QUARANTAINE')).toBe(false);
    expect(transitionAutorisee('ARCHIVEE', 'VALIDEE')).toBe(false);
    expect(transitionAutorisee('REJETEE', 'VALIDEE')).toBe(false);
  });

  it("[RG-M1-05] une soumission ne peut pas etre publiee sans passer par la quarantaine", () => {
    // C'est la garantie de qualite des donnees exigee par RG-M1-01.
    expect(transitionAutorisee('NOUVELLE', 'VALIDEE')).toBe(false);
  });

  it('[RG-M1-02] le code unique respecte le format CMR-<RESEAU>-<MIN>-<STRUCT>-<SEQ>', () => {
    expect(codeProducteurValide('CMR-NUM-MINPOSTEL-ANTIC-0001')).toBe(true);
    expect(codeProducteurValide('CMR-AGR-MINADER-SODECAO-0042')).toBe(true);
  });

  it('[RG-M1-02] un code mal forme est rejete', () => {
    expect(codeProducteurValide('CMR-NUM-MINPOSTEL')).toBe(false);
    expect(codeProducteurValide('cmr-num-minpostel-antic-0001')).toBe(false);
    expect(codeProducteurValide('CMR-NUM-MINPOSTEL-ANTIC-1')).toBe(false);
    expect(codeProducteurValide('')).toBe(false);
  });

  it('[RG-M1-03] deux fiches au meme triplet sigle/ministere/commune sont des doublons potentiels', () => {
    expect(cleDeDoublon('ANTIC', 'MINPOSTEL', 'Yaounde')).toBe(cleDeDoublon('antic', 'minpostel', 'YAOUNDE'));
  });

  it('[RG-M1-03] les accents et espaces multiples ne creent pas de faux negatifs', () => {
    expect(cleDeDoublon('SODECAO', 'MINADER', 'Ebolowa')).toBe(cleDeDoublon('SODECAO', 'MINADER', 'Ébolowa'));
    expect(cleDeDoublon('CDC', 'MINADER', 'Buea')).toBe(cleDeDoublon('CDC', 'MINADER', 'Buea  '));
  });

  it("[RG-M1-03] deux services deconcentres de communes differentes ne sont PAS des doublons", () => {
    // Le cas metier que la regle doit explicitement preserver.
    expect(cleDeDoublon('DRMINADER', 'MINADER', 'Bertoua'))
      .not.toBe(cleDeDoublon('DRMINADER', 'MINADER', 'Maroua'));
  });
});

describe('Module M2 — visualisation cartographique', () => {
  it('[RG-M2-01] seules les fiches VALIDEE ou EDITEE sont visibles sur la carte publique', () => {
    expect(visibleSurCartePublique('VALIDEE')).toBe(true);
    expect(visibleSurCartePublique('EDITEE')).toBe(true);
    expect(visibleSurCartePublique('QUARANTAINE')).toBe(false);
    expect(visibleSurCartePublique('REJETEE')).toBe(false);
    expect(visibleSurCartePublique('ARCHIVEE')).toBe(false);
    expect(visibleSurCartePublique('NOUVELLE')).toBe(false);
  });

  it("[RG-M2-03] des coordonnees reelles du Cameroun sont dans l'enveloppe", () => {
    expect(coordonneesDansEnveloppeCameroun(3.8592, 11.5180)).toBe(true);   // Archives Nationales, Yaounde
    expect(coordonneesDansEnveloppeCameroun(4.0417, 9.6852)).toBe(true);    // Conseil regional du Littoral
    expect(coordonneesDansEnveloppeCameroun(10.5882, 14.2972)).toBe(true);  // Conseil regional Extreme-Nord
  });

  it("[RG-M2-03] des coordonnees hors du territoire sont exclues de la carte", () => {
    expect(coordonneesDansEnveloppeCameroun(48.8566, 2.3522)).toBe(false);  // Paris
    expect(coordonneesDansEnveloppeCameroun(0, 0)).toBe(false);             // ile nulle
    expect(coordonneesDansEnveloppeCameroun(6.5244, 3.3792)).toBe(false);   // Lagos
  });

  it('[RG-M2-03] des coordonnees absentes ou non numeriques sont exclues', () => {
    expect(coordonneesDansEnveloppeCameroun(Number.NaN, 11.5)).toBe(false);
    expect(coordonneesDansEnveloppeCameroun(Number.POSITIVE_INFINITY, 11.5)).toBe(false);
  });
});

describe('Module M3 — tableaux de bord', () => {
  it("[RG-M3-02] aucune statistique n'est publiee sur un echantillon inferieur a 5", () => {
    expect(agregatPubliable(4)).toBe(false);
    expect(agregatPubliable(5)).toBe(true);
    expect(agregatPubliable(0)).toBe(false);
  });

  it('[RG-M3-01] un producteur remplissant tous les criteres obtient un indice de 100', () => {
    expect(indiceMaturiteArchivistique({
      serviceArchivesDedie: true, personnelForme: true, locauxAdaptes: true,
      planDeClassement: true, calendrierConservation: true, instrumentsRecherche: true,
    })).toBe(100);
  });

  it("[RG-M3-01] un producteur ne remplissant aucun critere obtient un indice de 0", () => {
    expect(indiceMaturiteArchivistique({
      serviceArchivesDedie: false, personnelForme: false, locauxAdaptes: false,
      planDeClassement: false, calendrierConservation: false, instrumentsRecherche: false,
    })).toBe(0);
  });

  it("[RG-M3-01] la ponderation respecte l'annexe F", () => {
    // 25 % service + 20 % locaux = 45.
    expect(indiceMaturiteArchivistique({
      serviceArchivesDedie: true, personnelForme: false, locauxAdaptes: true,
      planDeClassement: false, calendrierConservation: false, instrumentsRecherche: false,
    })).toBe(45);
  });

  it('[RG-M3-01] la somme des ponderations vaut exactement 1', () => {
    // Invariant structurel : une derive ici fausserait tous les indices nationaux.
    const somme = Object.values(PONDERATION_MATURITE).reduce((a, b) => a + b, 0);
    expect(somme).toBeCloseTo(1, 10);
  });
});

describe('Confidentialite et protection des donnees', () => {
  it('[NFR-C4-04] une extraction de plus de 100 fiches doit etre tracee nominativement', () => {
    expect(extractionDoitEtreTracee(101)).toBe(true);
    expect(extractionDoitEtreTracee(100)).toBe(false);
    expect(extractionDoitEtreTracee(1)).toBe(false);
  });
});

describe('Invariants du referentiel', () => {
  it('[AC-P1-06] le modele RBAC comporte exactement 8 roles', () => {
    expect(ROLES).toHaveLength(8);
    expect(new Set(ROLES).size).toBe(8);
  });

  it('les 9 reseaux archivistiques de la SND30 sont declares, sans doublon', () => {
    expect(RESEAUX_ARCHIVISTIQUES).toHaveLength(9);
    expect(new Set(RESEAUX_ARCHIVISTIQUES.map((r) => r.code)).size).toBe(9);
    expect(RESEAUX_ARCHIVISTIQUES.map((r) => r.numero)).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  });

  it('[NFR-C8-01] les 10 regions sont declarees en francais et en anglais', () => {
    expect(REGIONS).toHaveLength(10);
    for (const region of REGIONS) {
      expect(region.libelle.length).toBeGreaterThan(0);
      expect(region.libelleEn.length).toBeGreaterThan(0);
    }
  });

  it('[RG-M1-05] tout statut declare figure dans la table des transitions', () => {
    // Un statut ajoute sans transition correspondante produirait un blocage
    // silencieux du cycle de vie d'une fiche.
    for (const statut of STATUTS_FICHE) {
      expect(TRANSITIONS_AUTORISEES).toHaveProperty(statut);
    }
  });

  it('[RG-M1-05] toute transition declaree pointe vers un statut connu', () => {
    for (const cibles of Object.values(TRANSITIONS_AUTORISEES)) {
      for (const cible of cibles) expect(STATUTS_FICHE).toContain(cible);
    }
  });
});
