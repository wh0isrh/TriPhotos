import Photos

struct PhotoAlbum: Identifiable, Hashable {
    let localIdentifier: String
    let title: String
    var id: String { localIdentifier }
}

final class PhotoAlbumService {
    func albums() -> [PhotoAlbum] {
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var albums: [PhotoAlbum] = []
        result.enumerateObjects { collection, _, _ in
            guard let title = collection.localizedTitle, !title.isEmpty else { return }
            albums.append(PhotoAlbum(localIdentifier: collection.localIdentifier, title: title))
        }
        return albums.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func createAlbum(title: String, completion: @escaping (Result<PhotoAlbum, Error>) -> Void) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        var placeholderIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: trimmedTitle)
            placeholderIdentifier = request.placeholderForCreatedAssetCollection.localIdentifier
        }) { success, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)) }
                else if success, let identifier = placeholderIdentifier { completion(.success(PhotoAlbum(localIdentifier: identifier, title: trimmedTitle))) }
                else { completion(.failure(NSError(domain: "TriPhotos.Albums", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible de créer l’album."]))) }
            }
        }
    }

    func addAsset(localIdentifier: String, to album: PhotoAlbum, completion: @escaping (Result<Void, Error>) -> Void) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [album.localIdentifier], options: nil)
        guard let asset = assets.firstObject, let collection = collections.firstObject else {
            completion(.failure(NSError(domain: "TriPhotos.Albums", code: 2, userInfo: [NSLocalizedDescriptionKey: "Photo ou album introuvable."])))
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: collection)?.addAssets([asset] as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)) }
                else if success { completion(.success(())) }
                else { completion(.failure(NSError(domain: "TriPhotos.Albums", code: 3, userInfo: [NSLocalizedDescriptionKey: "Impossible d’ajouter la photo."]))) }
            }
        }
    }

    func markFavorite(localIdentifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            completion(.failure(NSError(domain: "TriPhotos.Albums", code: 4, userInfo: [NSLocalizedDescriptionKey: "Photo introuvable."])))
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest(for: asset)?.isFavorite = true
        }) { success, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)) }
                else if success { completion(.success(())) }
                else { completion(.failure(NSError(domain: "TriPhotos.Albums", code: 5, userInfo: [NSLocalizedDescriptionKey: "Impossible d’ajouter le favori."]))) }
            }
        }
    }
}

