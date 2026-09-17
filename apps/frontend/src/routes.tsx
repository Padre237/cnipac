import { lazy } from 'react';

/**
 * Routage et decoupage de code — SDD §20.3.
 *
 * Chaque route majeure est chargee paresseusement. La consequence pratique est
 * qu'un visiteur anonyme consultant la carte ne telecharge JAMAIS le code
 * d'administration ni celui du crowdsourcing — gain determinant sur une
 * connexion 3G (SRS §2.4.2), et regle verifiee en CI par
 * scripts/gate-bundle-budget.mjs (ADR-029).
 *
 * Le composant RequireRole est un garde d'EXPERIENCE UTILISATEUR uniquement :
 * il evite d'afficher des pages inutilisables. La securite effective reste
 * cote serveur, via les gardes RBAC de NestJS (SDD §18.3.1). Un contournement
 * du garde client se heurte immediatement a un 403.
 */
export const Cartographie  = lazy(() => import('./features/cartography/index.js'));
export const Producteur    = lazy(() => import('./features/producer/index.js'));
export const TableauDeBord = lazy(() => import('./features/dashboard/index.js'));
export const Ingestion     = lazy(() => import('./features/ingestion/index.js'));
export const Crowdsourcing = lazy(() => import('./features/crowdsourcing/index.js'));
export const Admin         = lazy(() => import('./features/admin/index.js'));
export const Authentification = lazy(() => import('./features/auth/index.js'));
