import { LANGUE_PAR_DEFAUT, REGIONS, RESEAUX_ARCHIVISTIQUES } from '@cnipac/shared-types';

/**
 * Coque applicative — Palier 0.
 *
 * Les ecrans sont decrits au SDD chapitre 21 et maquettes dans
 * docs/design/stitch/. Cette coque existe pour que la chaine de construction,
 * le budget de bundle (ADR-029) et les portes d'accessibilite (ADR-030) soient
 * operationnels avant le premier ecran.
 */
export function App() {
  return (
    <main lang={LANGUE_PAR_DEFAUT}>
      <h1>CNIPAC</h1>
      <p>
        Carte Numerique Interactive des Producteurs d&apos;Archives au Cameroun. Referentiel
        national institue par l&apos;article 26 de la Loi n&nbsp;2024/001.
      </p>
      <p>
        Socle technique en place : {RESEAUX_ARCHIVISTIQUES.length} reseaux archivistiques,{' '}
        {REGIONS.length} regions.
      </p>
    </main>
  );
}
