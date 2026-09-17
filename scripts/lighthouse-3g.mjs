#!/usr/bin/env node
/**
 * Mesure Lighthouse sous profil 3G — NFR-C1-01.
 * Profil de reference du SRS §2.4.2 : 1 Mbit/s, 100 ms de latence.
 * Indicatif en pull request ; la mesure contractuelle reste k6 en PREPROD.
 */
import { info, arguments_ } from './_lib.mjs';

const args = arguments_();
const url = args.url ?? 'http://localhost:4173';

info(`Profil 3G de reference (SRS §2.4.2) : 1 Mbit/s descendant, 100 ms RTT.`);
info(`Cible : ${url}`);
info('Palier 0 — integration Lighthouse CI a realiser au Sprint 5.');
info('Seuils vises : Performance >= 70, Accessibilite >= 95 (NFR-C7-01), Best Practices >= 90.');
