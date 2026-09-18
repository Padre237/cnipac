import { readFileSync } from 'node:fs';
import { Logger } from '@nestjs/common';

/**
 * Chargeur de secrets — ADR-033.
 *
 * Un secret ne se lit JAMAIS depuis une variable d'environnement : celle-ci est
 * visible dans `docker inspect`, dans /proc/<pid>/environ et dans les traces
 * d'erreur. La convention retenue est `<NOM>_FILE`, qui porte le CHEMIN d'un
 * fichier monte en Docker secret (donc en tmpfs, jamais sur le disque).
 *
 * scripts/gate-secrets.mjs echoue en CI si du code lit directement une variable
 * d'environnement dont le nom evoque un secret.
 */
const journal = new Logger('ChargeurSecrets');

export function lireSecret(
  nom: string,
  options: { obligatoire?: boolean } = {},
): string | undefined {
  const { obligatoire = true } = options;
  const chemin = process.env[`${nom}_FILE`];

  if (chemin) {
    try {
      // trimEnd() seulement : un secret peut legitimement commencer par un espace.
      return readFileSync(chemin, 'utf8').trimEnd();
    } catch (erreur) {
      journal.error(`Secret ${nom} illisible depuis ${chemin} : ${(erreur as Error).message}`);
      if (obligatoire) {
        throw new Error(
          `Secret obligatoire ${nom} illisible. Verifier le montage Docker secret ` +
            `et les droits du fichier (0400, proprietaire root). Voir ADR-033.`,
        );
      }
      return undefined;
    }
  }

  // Repli sur la variable directe, TOLERE UNIQUEMENT en developpement local.
  const valeurDirecte = process.env[nom];
  if (valeurDirecte) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        `Le secret ${nom} est fourni par variable d'environnement en production. ` +
          `ADR-033 l'interdit : utiliser ${nom}_FILE avec un Docker secret. ` +
          `Une variable d'environnement est exposee par docker inspect et /proc.`,
      );
    }
    journal.warn(
      `Secret ${nom} lu depuis une variable d'environnement (tolere hors production uniquement).`,
    );
    return valeurDirecte;
  }

  if (obligatoire) {
    throw new Error(
      `Secret obligatoire ${nom} absent. Definir ${nom}_FILE (production) ou ${nom} (developpement).`,
    );
  }
  return undefined;
}
