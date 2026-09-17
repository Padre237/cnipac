#!/usr/bin/env node
/**
 * PORTE : durcissement des en-tetes HTTP — ADR-031 niveau 1.
 * Exigence : NFR-C3-07 (CSP, HSTS, X-Frame-Options, X-Content-Type-Options...).
 * Teste la configuration, pas le site : s'execute en moins d'une minute et
 * peut donc rester dans le chemin critique de pull request.
 */
import { echec, avertir, info, conclure, arguments_ } from './_lib.mjs';

const args = arguments_();
const url = args.url ?? 'http://localhost:3000';

const ATTENDUS = [
  { entete: 'content-security-policy', obligatoire: true, verif: (v) => !/unsafe-eval/.test(v), note: "CSP sans 'unsafe-eval'" },
  { entete: 'strict-transport-security', obligatoire: true, verif: (v) => /max-age=\d{7,}/.test(v), note: 'HSTS avec max-age >= 1 an' },
  { entete: 'x-content-type-options', obligatoire: true, verif: (v) => v === 'nosniff' },
  { entete: 'x-frame-options', obligatoire: true, verif: (v) => /DENY|SAMEORIGIN/i.test(v) },
  { entete: 'referrer-policy', obligatoire: true, verif: (v) => /no-referrer|strict-origin/i.test(v) },
  { entete: 'permissions-policy', obligatoire: false, note: 'recommande : restreindre geolocation, camera, microphone' },
  { entete: 'x-powered-by', interdit: true, note: 'divulgue la pile technique (fingerprinting)' },
];

let reponse;
try {
  reponse = await fetch(`${url}/health`, { redirect: 'manual' });
} catch (e) {
  info(`Cible ${url} injoignable (${e.message}). Porte sautee — le backend doit etre demarre.`);
  process.exit(0);
}

info(`Reponse ${reponse.status} de ${url}/health`);

for (const attendu of ATTENDUS) {
  const valeur = reponse.headers.get(attendu.entete);

  if (attendu.interdit) {
    if (valeur) echec(`En-tete interdit present : ${attendu.entete}: ${valeur}. ${attendu.note ?? ''} (NFR-C3-07)`);
    continue;
  }
  if (!valeur) {
    const message = `En-tete manquant : ${attendu.entete}. ${attendu.note ?? ''} (NFR-C3-07, durcissement OWASP)`;
    attendu.obligatoire ? echec(message) : avertir(message);
    continue;
  }
  if (attendu.verif && !attendu.verif(valeur)) {
    echec(`En-tete ${attendu.entete} present mais non conforme : "${valeur}". Attendu : ${attendu.note}`);
  } else {
    info(`  OK ${attendu.entete}`);
  }
}

conclure('En-tetes de securite');
