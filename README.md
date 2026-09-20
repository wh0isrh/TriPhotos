# TriPhotos

Application iPhone native de tri de photos, 100 % locale et personnelle.

## Chaîne de build

Le projet Xcode est généré par XcodeGen dans GitHub Actions. Le dépôt ne versionne pas de fichier `.xcodeproj`.

Le workflow produit un artefact `TriPhotos-ipa` contenant une IPA non signée, installable ensuite avec AltStore après signature par AltServer.

## Développement

L’application cible iOS 17 et utilise SwiftUI en mode Swift 5. Les sources se trouvent dans `TriPhotos/`.

