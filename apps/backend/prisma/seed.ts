/**
 * Amorcage des donnees — ADR-034.
 *
 * REGLE ABSOLUE : aucune donnee reelle de personne physique.
 * Les coordonnees d'organismes publics (ministeres, conseils regionaux) sont
 * des donnees publiques issues du TDR et sont legitimes. Les correspondants,
 * telephones et courriels sont integralement synthetiques.
 *
 * Le generateur est DETERMINISTE : une meme graine produit un meme jeu, ce qui
 * rend les tests reproductibles.
 *
 * Trois jeux : --jeu=dev (50) | preprod (1 000) | charge (15 000).
 * Specification complete : docs/regles-metier/jeux-de-donnees.md
 */
async function amorcer(): Promise<void> {
  const jeu = process.argv.find((a) => a.startsWith('--jeu='))?.split('=')[1] ?? 'dev';
  console.log(`[seed] Jeu demande : ${jeu}`);
  console.log('[seed] Palier 0 — generateur a implementer au Sprint 2 (SDD §29.2).');
  console.log('[seed] Le jeu produit devra couvrir les cas limites des regles de gestion :');
  console.log(
    '       - 5 % de fiches sans coordonnees valides        (RG-M2-03, branche d exclusion)',
  );
  console.log(
    '       - des doublons deliberes sur le triplet          (RG-M1-03, parcours E2E P-B)',
  );
  console.log('       - tous les statuts de l automate                 (RG-M1-05)');
  console.log(
    '       - au moins une region a moins de 5 producteurs   (RG-M3-02, seuil d agregation)',
  );
  console.log('       - un indice de maturite reparti sur l echelle    (RG-M3-01)');
}

void amorcer();
