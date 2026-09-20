import Photos

enum PhotoLibraryAuthorization: Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted

    init(status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized: self = .authorized
        case .limited: self = .limited
        case .denied: self = .denied
        case .restricted: self = .restricted
        @unknown default: self = .denied
        }
    }
}

struct PhotoSource: Identifiable, Hashable {
    enum Kind: String, CaseIterable {
        case all, month, screenshots, videos, livePhotos, favorites, untriaged

        var title: String {
            switch self {
            case .all: return "Tout"
            case .month: return "Par mois / année"
            case .screenshots: return "Captures d’écran"
            case .videos: return "Vidéos"
            case .livePhotos: return "Live Photos"
            case .favorites: return "Favoris"
            case .untriaged: return "Jamais triées"
            }
        }

        var icon: String {
            switch self {
            case .all: return "photo.on.rectangle.angled"
            case .month: return "calendar"
            case .screenshots: return "rectangle.dashed"
            case .videos: return "video"
            case .livePhotos: return "livephoto"
            case .favorites: return "heart"
            case .untriaged: return "sparkles"
            }
        }
    }

    let kind: Kind
    let count: Int
    var id: Kind { kind }
}

final class PhotoLibraryService: @unchecked Sendable {
    func authorization() -> PhotoLibraryAuthorization {
        PhotoLibraryAuthorization(status: PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAuthorization(completion: @escaping (PhotoLibraryAuthorization) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(PhotoLibraryAuthorization(status: status))
            }
        }
    }

    func sources() -> [PhotoSource] {
        let allCount = PHAsset.fetchAssets(with: .unknown, options: nil).count
        let videosCount = PHAsset.fetchAssets(with: .video, options: nil).count
        let favoritesOptions = PHFetchOptions()
        favoritesOptions.predicate = NSPredicate(format: "favorite == YES")
        let favoritesCount = PHAsset.fetchAssets(with: .unknown, options: favoritesOptions).count

        return [
            PhotoSource(kind: .all, count: allCount),
            PhotoSource(kind: .month, count: countForCurrentMonth()),
            PhotoSource(kind: .screenshots, count: countForSmartAlbum(.smartAlbumScreenshots)),
            PhotoSource(kind: .videos, count: videosCount),
            PhotoSource(kind: .livePhotos, count: countForSmartAlbum(.smartAlbumLivePhotos)),
            PhotoSource(kind: .favorites, count: favoritesCount),
            PhotoSource(kind: .untriaged, count: allCount)
        ]
    }

    func fetchReferences(
        for kind: PhotoSource.Kind,
        referenceDate: Date? = nil,
        offset: Int = 0,
        limit: Int? = nil
    ) -> [PhotoAssetReference] {
        let result: PHFetchResult<PHAsset>
        switch kind {
        case .all, .untriaged:
            result = PHAsset.fetchAssets(with: .unknown, options: nil)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: nil)
        case .favorites:
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "favorite == YES")
            result = PHAsset.fetchAssets(with: .unknown, options: options)
        case .month:
            let calendar = Calendar.current
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate ?? Date())) ?? Date()
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
            result = PHAsset.fetchAssets(with: .unknown, options: options)
        case .screenshots:
            result = assetsInSmartAlbum(.smartAlbumScreenshots)
        case .livePhotos:
            result = assetsInSmartAlbum(.smartAlbumLivePhotos)
        }

        var references: [PhotoAssetReference] = []
        references.reserveCapacity(limit ?? result.count)
        result.enumerateObjects { asset, index, stop in
            guard index >= offset else { return }
            references.append(PhotoAssetReference(asset: asset))
            if let limit, references.count >= limit {
                stop.pointee = true
            }
        }
        return references
    }

    private func countForSmartAlbum(_ subtype: PHAssetCollectionSubtype) -> Int {
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
        guard let collection = collections.firstObject else { return 0 }
        return PHAsset.fetchAssets(in: collection, options: nil).count
    }

    private func assetsInSmartAlbum(_ subtype: PHAssetCollectionSubtype) -> PHFetchResult<PHAsset> {
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
        guard let collection = collections.firstObject else {
            return PHAsset.fetchAssets(withLocalIdentifiers: [], options: nil)
        }
        return PHAsset.fetchAssets(in: collection, options: nil)
    }

    private func countForCurrentMonth() -> Int {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate >= %@", start as NSDate)
        return PHAsset.fetchAssets(with: .unknown, options: options).count
    }
}
