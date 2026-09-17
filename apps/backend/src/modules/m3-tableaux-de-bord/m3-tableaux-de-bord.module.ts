import { Module } from '@nestjs/common';

/**
 * M3 — Tableaux de bord et analyse statistique
 *
 * Exigences fonctionnelles : FR-M3-01 a FR-M3-10
 * Regles de gestion        : RG-M3-01 a RG-M3-03
 * Conception detaillee     : SDD V4.0, chapitre correspondant.
 *
 * PALIER 0 — module declare et cable, sans logique metier.
 * Le squelette existe pour que la CI, les migrations, la documentation OpenAPI
 * et la matrice de tracabilite soient operationnels avant le premier
 * developpement fonctionnel (SDD §29.2 : « ce qui est livre, c'est la capacite
 * de livrer »).
 */
@Module({
  imports: [],
  controllers: [],
  providers: [],
  exports: [],
})
export class Um3UtableauxUdeUbordModule {}
