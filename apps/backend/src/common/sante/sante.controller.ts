import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

/**
 * Sondes de sante — exploitees par les healthchecks Docker, par les tests de
 * fumee du deploiement (SDD §26.5 etape 6) et par la supervision (ADR-038).
 *
 * Ces points d'entree ne sont accessibles que depuis le reseau interne :
 * la restriction est appliquee par Nginx (infra/nginx/conf.d/cnipac.conf).
 */
@ApiTags('sante')
@Controller('health')
export class SanteController {
  @Get()
  @ApiOperation({ summary: "Sonde de vivacite de l'application" })
  vivacite() {
    return {
      statut: 'ok',
      version: process.env.CNIPAC_VERSION ?? 'dev',
      horodatage: new Date().toISOString(),
    };
  }

  @Get('db')
  @ApiOperation({ summary: 'Connectivite PostgreSQL et disponibilite de PostGIS' })
  baseDeDonnees() {
    // Palier 0 : squelette. Implementation au Sprint 3 (SDD §29.2).
    // Doit verifier la connexion ET la presence de l'extension PostGIS :
    // une base sans PostGIS demarre mais rend le module M2 inoperant.
    return { statut: 'non_implemente', postgis: false };
  }

  @Get('redis')
  @ApiOperation({ summary: 'Connectivite Redis, base de revocation comprise' })
  redis() {
    // ADR-022 : verifier specifiquement la base 2 (revocation des jetons).
    // Sa perte reactive des jetons revoques : c'est une faille, pas une
    // degradation de performance.
    return { statut: 'non_implemente', base_revocation: false };
  }

  @Get('audit-chain')
  @ApiOperation({ summary: "Integrite de la chaine de hachage du journal d'audit" })
  chaineAudit() {
    // Art. 32 de la Loi 2024/001 et NFR-C3-05. Une rupture est l'evenement le
    // plus grave que le systeme puisse connaitre : alerte de criticite maximale
    // (ADR-038) et procedure de reponse a incident (SDD §23.12).
    return { statut: 'non_implemente', intacte: null };
  }
}
