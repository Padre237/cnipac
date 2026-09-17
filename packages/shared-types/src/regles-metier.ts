/**
 * Regles de gestion executables — SRS chapitre 11.
 *
 * Chaque fonction met en oeuvre une regle identifiee. Le nom de la regle figure
 * dans la documentation de la fonction ET dans le nom de son test unitaire, ce
 * qui alimente la matrice de tracabilite (ADR-035).
 *
 * Ces fonctions sont PURES : aucune dependance, aucun effet de bord. C'est ce
 * qui justifie l'exigence de 100 % de couverture sur ce paquet (ADR-028).
 */
import {
  ENVELOPPE_CAMEROUN,
  MOTIF_CODE_PRODUCTEUR,
  PONDERATION_MATURITE,
  SEUILS,
  STATUTS_VISIBLES_CARTE,
  TRANSITIONS_AUTORISEES,
  type StatutFiche,
} from './enumerations.js';

/**
 * RG-M1-05 — le statut d'une fiche suit un automate deterministe.
 * Aucune transition arriere n'est autorisee sans intervention tracee d'un
 * super-administrateur. Justification metier : garantir un cycle de vie
 * auditable de bout en bout.
 */
export function transitionAutorisee(depuis: StatutFiche, vers: StatutFiche): boolean {
  return TRANSITIONS_AUTORISEES[depuis]?.includes(vers) ?? false;
}

/**
 * RG-M2-03 — les producteurs sans coordonnees valides ne sont pas affiches sur
 * la carte, mais restent consultables dans la liste. Justification metier :
 * eviter les marqueurs aberrants sans perdre l'acces a la fiche.
 * Systeme de reference : WGS84 / EPSG:4326 (NFR-C5-04).
 */
export function coordonneesDansEnveloppeCameroun(latitude: number, longitude: number): boolean {
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return false;
  return (
    latitude >= ENVELOPPE_CAMEROUN.latitudeMin &&
    latitude <= ENVELOPPE_CAMEROUN.latitudeMax &&
    longitude >= ENVELOPPE_CAMEROUN.longitudeMin &&
    longitude <= ENVELOPPE_CAMEROUN.longitudeMax
  );
}

/**
 * RG-M2-01 — seules les fiches VALIDEE ou EDITEE apparaissent sur la carte.
 * Justification metier : garantir que le public ne voit que des donnees validees.
 */
export function visibleSurCartePublique(statut: StatutFiche): boolean {
  return STATUTS_VISIBLES_CARTE.includes(statut);
}

/**
 * RG-M3-02 — aucune statistique publique sur un echantillon inferieur a 5.
 * Justification metier : prevention de la re-identification.
 */
export function agregatPubliable(effectif: number): boolean {
  return effectif >= SEUILS.AGREGATION_MINIMALE;
}

/**
 * RG-M1-02 — le code unique est immuable. Cette fonction ne valide que la
 * FORME ; l'immuabilite releve de la couche de persistance et du garde-fou
 * de migrations (ADR-027).
 */
export function codeProducteurValide(code: string): boolean {
  return MOTIF_CODE_PRODUCTEUR.test(code);
}

/**
 * RG-M1-03 — deux soumissions sont des doublons potentiels si elles partagent
 * le triplet (sigle, ministere de tutelle, commune). Justification metier :
 * reduire les doublons sans bloquer a tort les services deconcentres, qui
 * partagent legitimement un sigle dans des communes differentes.
 */
export function cleDeDoublon(sigle: string, ministere: string, commune: string): string {
  const normaliser = (v: string) =>
    v.normalize('NFD').replace(/[̀-ͯ]/g, '').toUpperCase().trim().replace(/\s+/g, ' ');
  return [normaliser(sigle), normaliser(ministere), normaliser(commune)].join('|');
}

export interface CriteresMaturite {
  serviceArchivesDedie: boolean;
  personnelForme: boolean;
  locauxAdaptes: boolean;
  planDeClassement: boolean;
  calendrierConservation: boolean;
  instrumentsRecherche: boolean;
}

/**
 * RG-M3-01 — indice de maturite archivistique, formule ponderee de l'annexe F.
 * Resultat sur 100. Justification metier : garantir la reproductibilite et la
 * transparence de l'indicateur, qui sert au ciblage des inspections (art. 31-34).
 * Toute evolution de la ponderation fait l'objet d'une note officielle ANC.
 */
export function indiceMaturiteArchivistique(criteres: CriteresMaturite): number {
  let score = 0;
  for (const [critere, poids] of Object.entries(PONDERATION_MATURITE)) {
    if (criteres[critere as keyof CriteresMaturite]) score += poids;
  }
  return Math.round(score * 100);
}

/**
 * NFR-C4-04 — toute extraction de plus de 100 fiches est tracee nominativement
 * et notifiee a l'administrateur metier.
 */
export function extractionDoitEtreTracee(nombreFiches: number): boolean {
  return nombreFiches > SEUILS.EXPORT_TRACE_A_PARTIR_DE;
}
