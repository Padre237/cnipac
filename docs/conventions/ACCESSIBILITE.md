# Conventions d'accessibilité

**ADR** : [030](../adr/ADR-030-accessibilite-bloquante.md) · **Exigences** : NFR-C7-01 à NFR-C7-04

L'accessibilité n'est pas une passe de finition. Corrigée après coup, elle coûte
cinq à dix fois le prix de l'accessibilité construite — parce que les défauts
sont structurels et imposent de reprendre les composants.

## Les quatre exigences

| Exigence  | Contenu                                        | Comment c'est vérifié                                 |
| --------- | ---------------------------------------------- | ----------------------------------------------------- |
| NFR-C7-01 | WCAG 2.1 niveau AA                             | axe-core (composant + page), audit manuel trimestriel |
| NFR-C7-02 | Utilisable au clavier seul, **carte comprise** | Tests Playwright dédiés                               |
| NFR-C7-03 | Contraste 4,5:1 (normal), 3:1 (large)          | `scripts/gate-contrastes.mjs` sur les jetons          |
| NFR-C7-04 | Responsive dès 360×640                         | Tests multi-résolutions                               |

## Le point difficile : la carte

`NFR-C7-02` exige explicitement une navigation clavier pour « navigation,
formulaires, **carte** ». Les cartographies web sont notoirement défaillantes
sur ce point, et Leaflet ne le résout pas seul.

Ce que la carte CNIPAC doit offrir :

- déplacement et zoom aux flèches et aux touches `+` / `−` ;
- parcours des marqueurs à la tabulation, dans un ordre stable et prévisible ;
- ouverture de la fiche par `Entrée`, fermeture par `Échap` ;
- annonce du marqueur focalisé par le lecteur d'écran (`aria-label` portant le
  sigle et l'intitulé du producteur) ;
- **une alternative non cartographique** : la liste des producteurs, avec les
  mêmes filtres. Cette liste est de toute façon nécessaire, RG-M2-03 imposant
  que les fiches sans coordonnées valides y restent consultables.

## Écrire un composant accessible

```tsx
// Un test d'accessibilité accompagne chaque composant non trivial.
it('[NFR-C7-01] le formulaire de recherche est accessible', async () => {
  const { container } = render(<RechercheProducteur />);
  expect(await axe(container)).toHaveNoViolations();
});
```

Règles de base : un libellé associé à chaque champ, un `alt` sur chaque image
porteuse de sens (`alt=""` sur les images décoratives), jamais la couleur comme
seul porteur d'information, un focus toujours visible, une hiérarchie de titres
sans saut de niveau.

## Ce que l'automatisation ne voit pas

axe-core détecte environ **57 %** des critères WCAG. Restent à la charge de
l'humain : la pertinence des textes alternatifs, la cohérence de l'ordre de
tabulation, la clarté des messages d'erreur, la compréhension par un lecteur
d'écran réel. D'où l'audit manuel trimestriel (NVDA, VoiceOver) et l'audit
externe annuel prévus au SDD §25.7 — qui ne sont pas rendus redondants par la CI.
