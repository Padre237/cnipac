## Ce que fait cette PR

<!-- Une a trois phrases. Le titre doit respecter Conventional Commits (ADR-036) :
     type(portee): sujet — portees : m1..m7, backend, frontend, shared, db, infra, ci... -->

Refs: CNIPAC-

## Exigences couvertes

<!-- Identifiants du registre docs/traceability/exigences.json. Les tests doivent
     porter ces identifiants dans leur nom (ADR-035), sinon la CI echoue. -->

- [ ] FR- :
- [ ] NFR- :
- [ ] RG- :
- [ ] AC- :
- [ ] Aucune (refactoring, infrastructure, documentation)

## Verifications

- [ ] Tests unitaires ajoutes ou mis a jour ; seuils du palier courant tenus (ADR-028)
- [ ] Chaque regle de gestion touchee a un test dedie portant son identifiant
- [ ] Documentation mise a jour (README du module, ADR si un choix structurant est fait)
- [ ] Aucun secret, aucune donnee reelle, aucune donnee nominative introduite (ADR-033, ADR-034)

## Si la PR touche a la base de donnees

- [ ] Migration **retrocompatible** — prerequis du Blue-Green (ADR-032)
- [ ] Aucune operation destructive sur `evenement_audit`, `soumission_kobo`, `version_fiche` (ADR-027)
- [ ] Verrous evalues : pas de `ALTER TABLE` bloquant sur une grande table en heures ouvrees
- [ ] Procedure de retour arriere decrite ci-dessous

## Si la PR touche a l'API publique (M7)

- [ ] Changement **non rupturant**, ou nouvelle version d'API creee (ADR-037)
- [ ] Specification OpenAPI regeneree
- [ ] Aucun identifiant technique interne expose — seul le code unique perenne (RG-M1-02)

## Si la PR touche a l'interface

- [ ] Test d'accessibilite ajoute ; aucune violation `critical` ou `serious` (ADR-030)
- [ ] Navigable au clavier, focus visible (NFR-C7-02)
- [ ] Contrastes conformes (NFR-C7-03)
- [ ] Verifiee a 360x640 (NFR-C7-04)
- [ ] Chaines externalisees en FR et EN (NFR-C8-01)
- [ ] Impact sur le budget de bundle verifie (ADR-029)

## Impact et retour arriere

<!-- Que se passe-t-il si cette PR pose probleme en production ?
     Comment revient-on en arriere ? -->

## Points d'attention pour les relecteurs

<!-- Ce sur quoi vous voulez specifiquement un regard. -->
