# TriPhotos

Application iPhone personnelle de tri de photos, locale et sans dépendance externe.

## Télécharger et installer sur Windows

1. Ouvrir l’onglet [Actions](https://github.com/wh0isrh/TriPhotos/actions) du dépôt.
2. Ouvrir le dernier workflow vert **Build TriPhotos**.
3. Télécharger l’artefact **TriPhotos-ipa**, puis le décompresser pour obtenir `TriPhotos.ipa`.
4. Installer iTunes depuis [Apple](https://www.apple.com/itunes/download/win64), et non depuis le Microsoft Store.
5. Installer iCloud depuis le [lien direct Apple indiqué par AltStore](https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe), et non depuis le Microsoft Store. Si le lien direct ne fonctionne plus, consulter la [procédure Windows officielle AltStore](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows).
6. Installer [AltServer pour Windows](https://altstore.io/), le lancer comme administrateur, puis connecter l’iPhone en USB et accepter **Faire confiance**.
7. Dans iTunes, activer la synchronisation Wi-Fi de l’iPhone, puis utiliser AltServer → **Install AltStore** pour installer AltStore sur l’iPhone. Le mot de passe Apple se saisit uniquement dans AltServer, jamais dans ce dépôt ou dans le chat.
8. Dans AltServer, maintenir `Shift` en cliquant sur l’icône, choisir **Sideload .ipa…**, puis sélectionner `TriPhotos.ipa`.
9. Garder AltServer lancé et l’iPhone connecté en USB ou sur le même Wi-Fi pour le renouvellement de signature Apple gratuit.

La procédure officielle d’installation d’AltStore sur Windows est disponible dans la [documentation AltStore](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows). Sur iOS 16 ou ultérieur, activer aussi **Réglages → Confidentialité et sécurité → Mode développeur** si iOS le demande.

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
