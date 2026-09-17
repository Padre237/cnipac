#!/usr/bin/env node
/**
 * Rapport de conformite de jalon — ADR-035.
 * Piece a joindre au proces-verbal de recette (SRS §14.6) et a l'audit AC-P3-05.
 */
import { join } from 'node:path';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { RACINE, info, lireJson, arguments_ } from './_lib.mjs';

const args = arguments_();
const jalon = args.jalon ?? 'P1';
const sortie = args.sortie ?? `reports/conformite-${jalon}.md`;

const registre = lireJson(join(RACINE, 'docs/traceability/exigences.json'));
const cheminCouv = join(RACINE, 'docs/traceability/couverture.json');
const couverture = existsSync(cheminCouv) ? lireJson(cheminCouv).detail ?? {} : {};

const acs = registre.exigences.filter((e) => e.type === 'AC' && e.palier === jalon);
const frs = registre.exigences.filter((e) => e.type === 'FR' && e.palier === jalon);
const nfrs = registre.exigences.filter((e) => e.type === 'NFR');
const rgs = registre.exigences.filter((e) => e.type === 'RG');
const lois = registre.exigences.filter((e) => e.type === 'LOI');

const L = [];
L.push(`# Rapport de conformite — jalon ${jalon}`);
L.push('');
L.push(`**Projet** : CNIPAC — Carte Numerique Interactive des Producteurs d'Archives au Cameroun`);
L.push(`**Maitre d'ouvrage** : CENADI (MINFI) en partenariat avec les ANC (MINAC)`);
L.push(`**Date d'edition** : ${new Date().toISOString().slice(0, 10)}`);
L.push('');
L.push('Ce rapport est genere automatiquement a partir du registre des exigences et des');
L.push("identifiants portes par les tests automatises. Il constitue la piece justificative");
L.push('a joindre au proces-verbal de recette du jalon (SRS §14.6).');
L.push('');

const tableau = (titre, liste, colonne = 'Libelle') => {
  L.push(`## ${titre}`);
  L.push('');
  L.push(`| ID | ${colonne} | Couverture | Verification |`);
  L.push('|---|---|---|---|');
  for (const e of liste.sort((a, b) => a.id.localeCompare(b.id))) {
    const c = couverture[e.id];
    const statut = c ? 'Couverte' : 'NON COUVERTE';
    L.push(`| \`${e.id}\` | ${(e.libelle ?? '').replace(/\|/g, '/').slice(0, 120)} | ${statut} | ${e.methode_verification ?? e.verification ?? '—'} |`);
  }
  const n = liste.filter((e) => couverture[e.id]).length;
  L.push('');
  L.push(`**Taux de couverture : ${n}/${liste.length} (${liste.length ? Math.round((n / liste.length) * 100) : 0} %)**`);
  L.push('');
};

tableau(`Criteres d'acceptation du jalon ${jalon}`, acs, "Critere");
tableau(`Exigences fonctionnelles du jalon ${jalon}`, frs);
tableau('Exigences non fonctionnelles (toutes categories)', nfrs);
tableau('Regles de gestion', rgs);

L.push('## Conformite a la Loi n 2024/001 du 24 juillet 2024');
L.push('');
L.push('| Article | Disposition | Exigences de couverture | Etat |');
L.push('|---|---|---|---|');
for (const loi of lois) {
  const ids = loi.exigences_de_couverture ?? [];
  const couvertes = ids.filter((id) => couverture[id]).length;
  const etat = ids.length === 0 ? 'Aucune exigence rattachee' : `${couvertes}/${ids.length} couverte(s)`;
  L.push(`| ${loi.article} | ${loi.libelle} | ${ids.join(', ') || '—'} | ${etat} |`);
}
L.push('');
L.push('## Reserves et exclusions');
L.push('');
L.push('Les exigences marquees NON COUVERTE ne disposent d\'aucun test automatise portant');
L.push('leur identifiant a la date d\'edition. Elles doivent faire l\'objet soit d\'un test,');
L.push('soit d\'une reserve formelle inscrite au proces-verbal de recette.');
L.push('');
L.push('## Derogations contractuelles en vigueur');
L.push('');
L.push('Se reporter a [docs/DEROGATIONS.md](../docs/DEROGATIONS.md) pour les ecarts assumes');
L.push('au SRS V2.0 et au SDD V4.0 soumis a la validation du Comite de Pilotage.');

const chemin = join(RACINE, sortie);
mkdirSync(join(chemin, '..'), { recursive: true });
writeFileSync(chemin, L.join('\n'));
info(`Rapport de conformite ecrit : ${sortie}`);
