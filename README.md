# TriPhotos

Application iPhone personnelle de tri de photos, locale et sans dépendance externe.

## Télécharger et installer

1. Ouvrir l’onglet [Actions](https://github.com/wh0isrh/TriPhotos/actions) du dépôt.
2. Ouvrir le dernier workflow vert **Build TriPhotos**.
3. Télécharger l’artefact **TriPhotos-ipa**, puis le décompresser pour obtenir `TriPhotos.ipa`.
4. Installer l’IPA avec AltServer sur Windows : clic droit sur l’icône AltServer avec la touche `Shift`, puis **Sideload .ipa…**.
5. Garder AltServer lancé et l’iPhone connecté en USB ou sur le même Wi-Fi pour le renouvellement de signature Apple gratuit.

La procédure officielle d’installation d’AltStore sur Windows est disponible dans la [documentation AltStore](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows).

## Premier test conseillé

- Laisser **Mode simulation** activé.
- Autoriser l’accès Photos complet ou limité.
- Ouvrir une petite source et tester garder, supprimer, album/favori et annuler.
- Fermer puis relancer l’app pour vérifier que les photos triées ne réapparaissent pas.
- Ouvrir **File de suppression**, décocher une photo et lancer la simulation.
- Ne désactiver le mode simulation qu’après ces vérifications.

## Chaîne de build

Le projet Xcode est généré par XcodeGen dans GitHub Actions. Aucun `.xcodeproj` n’est versionné.

Le workflow utilise un runner `macos-15`, génère le projet, compile une app non signée avec Swift 5/iOS 17, vérifie les métadonnées Info.plist, puis produit l’artefact `TriPhotos-ipa`.

## Développement

Les sources sont dans `TriPhotos/`. Tout nouveau fichier Swift placé dans ce dossier est inclus automatiquement par XcodeGen. L’app utilise SwiftUI, PhotoKit et SwiftData, sans SDK tiers ni requête réseau applicative.
