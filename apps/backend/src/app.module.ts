import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { SEUILS } from '@cnipac/shared-types';

import { SanteController } from './common/sante/sante.controller.js';
import { M1IngestionModule } from './modules/m1-ingestion/m1-ingestion.module.js';
import { M2CartographieModule } from './modules/m2-cartographie/m2-cartographie.module.js';
import { M3TableauxDeBordModule } from './modules/m3-tableaux-de-bord/m3-tableaux-de-bord.module.js';
import { M4ProducteursModule } from './modules/m4-producteurs/m4-producteurs.module.js';
import { M5CrowdsourcingModule } from './modules/m5-crowdsourcing/m5-crowdsourcing.module.js';
import { M6AdminModule } from './modules/m6-admin/m6-admin.module.js';
import { M7ApiPubliqueModule } from './modules/m7-api-publique/m7-api-publique.module.js';

/**
 * Module racine — architecture monolithique modulaire (ADR-008 du SDD).
 * Les sept modules fonctionnels du SRS chapitre 5 sont cables des le Palier 0 :
 * la structure precede la fonctionnalite.
 */
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true }),
    ScheduleModule.forRoot(),

    // NFR-C3-08 : 5 tentatives par tranche de 10 minutes. Le seuil vient du
    // paquet partage : il n'existe qu'a un seul endroit dans tout le systeme.
    ThrottlerModule.forRoot([
      {
        name: 'authentification',
        ttl: SEUILS.FENETRE_ANTI_FORCE_BRUTE_MINUTES * 60_000,
        limit: SEUILS.TENTATIVES_AUTHENTIFICATION_MAX,
      },
      { name: 'defaut', ttl: 60_000, limit: 120 },
    ]),

    M1IngestionModule,
    M2CartographieModule,
    M3TableauxDeBordModule,
    M4ProducteursModule,
    M5CrowdsourcingModule,
    M6AdminModule,
    M7ApiPubliqueModule,
  ],
  controllers: [SanteController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
