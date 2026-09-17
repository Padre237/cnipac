import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module.js';

async function amorcer() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  const journal = new Logger('Amorcage');

  // NFR-C3-07 — durcissement des en-tetes. Verifie a chaque PR par
  // scripts/gate-entetes-securite.mjs (ADR-031 niveau 1).
  // Nginx pose les memes en-tetes en production : defense en profondeur, et le
  // backend reste correctement durci s'il est un jour expose directement.
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"],                // pas d'unsafe-eval : la CI le refuse
          styleSrc: ["'self'", "'unsafe-inline'"],
          imgSrc: ["'self'", 'data:', 'blob:', 'https://*.tile.openstreetmap.org'],
          connectSrc: ["'self'"],
          frameAncestors: ["'none'"],
        },
      },
      hsts: { maxAge: 31_536_000, includeSubDomains: true, preload: true },
      referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    }),
  );
  app.disable('x-powered-by');   // NFR-C3-07 : pas d'empreinte de pile technique

  // Validation stricte des entrees (anti-injection, SDD §4.2).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: false },
    }),
  );

  // ADR-037 — versionnage de l'API par chemin. Le prefixe /health reste hors
  // versionnage : c'est une interface d'exploitation, pas un contrat public.
  app.setGlobalPrefix(`api/${process.env.API_VERSION ?? 'v1'}`, {
    exclude: ['health', 'health/(.*)', 'metrics'],
  });

  // NFR-C5-01 : specification OpenAPI 3.x. Elle alimente aussi le scan DAST
  // guide par la specification (ADR-031) et la detection de rupture de contrat.
  const configurationSwagger = new DocumentBuilder()
    .setTitle('API CNIPAC')
    .setDescription(
      "Carte Numerique Interactive des Producteurs d'Archives au Cameroun. " +
      "Mise en oeuvre de l'article 26 de la Loi n 2024/001 du 24 juillet 2024 " +
      '(fichier unique et accessible des producteurs d\'archives publiques).',
    )
    .setVersion(process.env.CNIPAC_VERSION ?? '0.1.0')
    .addBearerAuth()
    .addTag('sante', 'Sondes d\'exploitation')
    .addTag('m1-ingestion', 'Synchronisation KoboToolbox')
    .addTag('m2-cartographie', 'Visualisation cartographique')
    .addTag('m3-tableaux-de-bord', 'Tableaux de bord et analyse')
    .addTag('m4-producteurs', 'Gestion des producteurs')
    .addTag('m5-crowdsourcing', 'Crowdsourcing securise')
    .addTag('m6-admin', 'Administration, securite, RBAC')
    .addTag('m7-api-publique', 'API ouverte et interoperabilite')
    .build();
  SwaggerModule.setup('api/docs', app, SwaggerModule.createDocument(app, configurationSwagger));

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  journal.log(`API CNIPAC a l'ecoute sur le port ${port} (fuseau ${process.env.TZ ?? 'systeme'})`);
}

void amorcer();
