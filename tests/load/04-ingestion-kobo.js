// Scénario de charge k6 — 04-ingestion-kobo. Palier 0 : squelette.
// Implémentation au Sprint 12 (Palier 2), avant la recette AC-P2-09.
// Les seuils ci-dessous sont contractuels : ils viennent du SRS chapitre 10.
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  thresholds: {
    // À compléter selon le tableau de tests/load/README.md.
    http_req_duration: ['p(95)<5000'],
    http_req_failed: ['rate<0.01'],
  },
  stages: [
    { duration: '1m', target: 10 },
    { duration: '5m', target: 50 },
    { duration: '1m', target: 0 },
  ],
};

export default function () {
  const reponse = http.get(`${__ENV.CNIPAC_BASE_URL || 'http://localhost:8080'}/health`);
  check(reponse, { 'statut 200': (r) => r.status === 200 });
}
