/**
 * Enumerations metier CNIPAC — SOURCE DE VERITE UNIQUE (ADR-013).
 *
 * Toute valeur declaree ici est consommee a l'identique par le backend et par
 * le frontend. C'est ce qui empeche la divergence silencieuse du referentiel
 * national, principal risque d'un decoupage en deux depots.
 *
 * Chaque enumeration porte la reference du document qui la fonde. Ne rien
 * ajouter ici sans reference : le referentiel d'un systeme d'Etat n'est pas
 * une affaire de convenance de developpement.
 */

// ---------------------------------------------------------------------------
// Cycle de vie d'une fiche producteur — RG-M1-05.
// L'automate est strict : NOUVELLE -> QUARANTAINE -> VALIDEE -> (EDITEE)* -> ARCHIVEE.
// Aucune transition arriere sans intervention tracee d'un super-administrateur.
// ---------------------------------------------------------------------------
// CASSE : minuscules, conformement au type statut_fiche_enum du SDD §12.2 —
// c'est la valeur reellement stockee en base. Le SRS §12.9 (MT.03) les ecrit en
// majuscules ; la divergence est signalee en A-07 de docs/ANOMALIES-DOCUMENTAIRES.md.
// Comparer une valeur issue de la base a « VALIDEE » ne matcherait jamais.
export const STATUTS_FICHE = [
  'nouvelle',
  'quarantaine',
  'validee',
  'editee',
  'rejetee',
  'archivee',
] as const;
export type StatutFiche = (typeof STATUTS_FICHE)[number];

/** Transitions autorisees par RG-M1-05. Toute transition absente est interdite. */
export const TRANSITIONS_AUTORISEES: Readonly<Record<StatutFiche, readonly StatutFiche[]>> =
  Object.freeze({
    nouvelle: ['quarantaine'],
    quarantaine: ['validee', 'rejetee'],
    validee: ['editee', 'archivee'],
    editee: ['editee', 'archivee'],
    rejetee: [], // terminal — une correction passe par une nouvelle soumission
    archivee: [], // terminal — RG-M4-yy : archivage logique, jamais suppression
  });

/** RG-M2-01 : seules ces fiches apparaissent sur la carte publique. */
export const STATUTS_VISIBLES_CARTE: readonly StatutFiche[] = Object.freeze(['validee', 'editee']);

/** Libelles d'affichage. NFR-C8-01 : les deux langues officielles. */
export const LIBELLES_STATUT_FICHE: Readonly<Record<StatutFiche, { fr: string; en: string }>> =
  Object.freeze({
    nouvelle: { fr: 'Nouvelle', en: 'New' },
    quarantaine: { fr: 'En quarantaine', en: 'In quarantine' },
    validee: { fr: 'Validée', en: 'Validated' },
    editee: { fr: 'Éditée', en: 'Edited' },
    rejetee: { fr: 'Rejetée', en: 'Rejected' },
    archivee: { fr: 'Archivée', en: 'Archived' },
  });

// ---------------------------------------------------------------------------
// Roles RBAC — SRS §6.2. Huit roles, ni plus ni moins (AC-P1-06).
// ---------------------------------------------------------------------------
export const ROLES = ['R-01', 'R-02', 'R-03', 'R-04', 'R-05', 'R-06', 'R-07', 'R-08'] as const;
export type Role = (typeof ROLES)[number];

export const LIBELLES_ROLES: Readonly<Record<Role, string>> = Object.freeze({
  'R-01': 'Super-administrateur systeme',
  'R-02': 'Administrateur metier ANC',
  'R-03': 'Archiviste validateur',
  'R-04': 'Archiviste consultation',
  'R-05': 'Point focal archives',
  'R-06': 'Decideur / Inspecteur archivistique',
  'R-07': 'Agent terrain (vue avancement)',
  'R-08': 'Chercheur / API publique',
});

/** SRS §6.5.3 : MFA obligatoire pour R-01, recommandee pour R-02 et R-03. */
export const ROLES_MFA_OBLIGATOIRE: readonly Role[] = Object.freeze(['R-01']);
export const ROLES_MFA_RECOMMANDEE: readonly Role[] = Object.freeze(['R-02', 'R-03']);

// ---------------------------------------------------------------------------
// Reseaux archivistiques — TDR §7, alignes sur la SND30. Exactement neuf.
// ---------------------------------------------------------------------------
export const RESEAUX_ARCHIVISTIQUES = [
  { code: 'ENE', numero: 1, libelle: 'Energie', libelleEn: 'Energy' },
  { code: 'AGR', numero: 2, libelle: 'Agro-industrie', libelleEn: 'Agro-industry' },
  { code: 'NUM', numero: 3, libelle: 'Numerique', libelleEn: 'Digital' },
  { code: 'FOR', numero: 4, libelle: 'Foret-Bois', libelleEn: 'Forestry and Timber' },
  {
    code: 'TEX',
    numero: 5,
    libelle: 'Textile-Confection-Cuir',
    libelleEn: 'Textile, Clothing and Leather',
  },
  {
    code: 'MIN',
    numero: 6,
    libelle: 'Mines-Metallurgie-Siderurgie',
    libelleEn: 'Mining, Metallurgy and Steel',
  },
  {
    code: 'HYD',
    numero: 7,
    libelle: 'Hydrocarbures-Petrochimie-Raffinage',
    libelleEn: 'Hydrocarbons, Petrochemicals and Refining',
  },
  {
    code: 'CHI',
    numero: 8,
    libelle: 'Chimie-Pharmacie',
    libelleEn: 'Chemicals and Pharmaceuticals',
  },
  {
    code: 'CST',
    numero: 9,
    libelle: 'Construction-Services professionnels, scientifiques et techniques',
    libelleEn: 'Construction and Professional, Scientific and Technical Services',
  },
] as const;
export type CodeReseau = (typeof RESEAUX_ARCHIVISTIQUES)[number]['code'];

// ---------------------------------------------------------------------------
// Regions du Cameroun — dix regions. Codes ISO 3166-2:CM.
// ---------------------------------------------------------------------------
export const REGIONS = [
  { code: 'AD', libelle: 'Adamaoua', libelleEn: 'Adamawa', chefLieu: 'Ngaoundere' },
  { code: 'CE', libelle: 'Centre', libelleEn: 'Centre', chefLieu: 'Yaounde' },
  { code: 'ES', libelle: 'Est', libelleEn: 'East', chefLieu: 'Bertoua' },
  { code: 'EN', libelle: 'Extreme-Nord', libelleEn: 'Far North', chefLieu: 'Maroua' },
  { code: 'LT', libelle: 'Littoral', libelleEn: 'Littoral', chefLieu: 'Douala' },
  { code: 'NO', libelle: 'Nord', libelleEn: 'North', chefLieu: 'Garoua' },
  { code: 'NW', libelle: 'Nord-Ouest', libelleEn: 'North-West', chefLieu: 'Bamenda' },
  { code: 'OU', libelle: 'Ouest', libelleEn: 'West', chefLieu: 'Bafoussam' },
  { code: 'SU', libelle: 'Sud', libelleEn: 'South', chefLieu: 'Ebolowa' },
  { code: 'SW', libelle: 'Sud-Ouest', libelleEn: 'South-West', chefLieu: 'Buea' },
] as const;
export type CodeRegion = (typeof REGIONS)[number]['code'];

// ---------------------------------------------------------------------------
// Enveloppe territoriale du Cameroun — RG-M2-03.
// Une fiche dont les coordonnees sortent de cette enveloppe n'est PAS affichee
// sur la carte, mais reste consultable dans la liste des producteurs.
// Systeme de coordonnees : WGS84 / EPSG:4326 (NFR-C5-04).
// ---------------------------------------------------------------------------
export const ENVELOPPE_CAMEROUN = Object.freeze({
  longitudeMin: 8.5,
  latitudeMin: 1.6,
  longitudeMax: 16.2,
  latitudeMax: 13.1,
  epsg: 4326,
});

// ---------------------------------------------------------------------------
// Langues — NFR-C8-01. Les deux langues officielles (art. 58 Loi 2024/001).
// ---------------------------------------------------------------------------
export const LANGUES = ['fr', 'en'] as const;
export type Langue = (typeof LANGUES)[number];
export const LANGUE_PAR_DEFAUT: Langue = 'fr';

// ---------------------------------------------------------------------------
// Seuils metier chiffres, extraits des regles de gestion.
// Ils sont ici pour n'exister qu'a UN seul endroit dans tout le systeme.
// ---------------------------------------------------------------------------
export const SEUILS = Object.freeze({
  /** RG-M3-02 : aucune statistique publique sur un echantillon inferieur a 5,
   *  afin de prevenir la re-identification. */
  AGREGATION_MINIMALE: 5,

  /** NFR-C4-04 : toute extraction au-dela de ce volume est tracee nominativement
   *  et notifiee a l'administrateur metier. */
  EXPORT_TRACE_A_PARTIR_DE: 100,

  /** NFR-C3-08 : 5 tentatives par tranche de 10 minutes, par IP et par compte. */
  TENTATIVES_AUTHENTIFICATION_MAX: 5,
  FENETRE_ANTI_FORCE_BRUTE_MINUTES: 10,

  /** FR-M1-01 et AC-P1-01 : une soumission Kobo doit parvenir en quarantaine
   *  en moins de 15 minutes. */
  DELAI_INGESTION_KOBO_MINUTES: 15,

  /** RG-M3-03 : les indicateurs nationaux sont rafraichis quotidiennement a
   *  03h00 UTC+1, et l'horodatage de fraicheur est toujours affiche. */
  HEURE_RAFRAICHISSEMENT_INDICATEURS: '03:00',

  /** ADR-037 : au-dela, la PWA avertit que les donnees peuvent etre obsoletes. */
  CACHE_PWA_DONNEES_HEURES: 24,
  CACHE_PWA_ALERTE_JOURS: 7,
});

// ---------------------------------------------------------------------------
// Indice de maturite archivistique — RG-M3-01, ponderation de l'annexe F.
// Toute evolution de cette formule fait l'objet d'une note officielle ANC.
// La somme des ponderations DOIT valoir 1 : un test unitaire le verifie.
// ---------------------------------------------------------------------------
export const PONDERATION_MATURITE = Object.freeze({
  serviceArchivesDedie: 0.25,
  personnelForme: 0.15,
  locauxAdaptes: 0.2,
  planDeClassement: 0.2,
  calendrierConservation: 0.1,
  instrumentsRecherche: 0.1,
});

// ---------------------------------------------------------------------------
// Code unique du producteur — RG-M1-02.
// Format : CMR-<RESEAU>-<MIN>-<STRUCT>-<SEQ>
// Genere automatiquement a la validation, JAMAIS modifiable. Il fonde la
// perennite des URI de l'API publique (FR-M7-04, ADR-037).
// ---------------------------------------------------------------------------
// Expression IDENTIQUE a la contrainte chk_producteur_code_producteur_format
// du SDD §12.3. Aucune longueur de segment n'y est plafonnee — et c'est
// necessaire : MINPOSTEL fait 9 caracteres, MINCOMMERCE 11.
export const MOTIF_CODE_PRODUCTEUR = /^CMR-[A-Z0-9]+-[A-Z0-9]+-[A-Z0-9]+-[0-9]+$/;
