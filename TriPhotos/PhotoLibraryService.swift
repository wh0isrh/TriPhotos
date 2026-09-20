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

    func sources(excluding excludedIdentifiers: Set<String> = []) -> [PhotoSource] {
        return [
            PhotoSource(kind: .all, count: count(for: .all, excluding: excludedIdentifiers)),
            PhotoSource(kind: .month, count: count(for: .month, excluding: excludedIdentifiers)),
            PhotoSource(kind: .screenshots, count: count(for: .screenshots, excluding: excludedIdentifiers)),
            PhotoSource(kind: .videos, count: count(for: .videos, excluding: excludedIdentifiers)),
            PhotoSource(kind: .livePhotos, count: count(for: .livePhotos, excluding: excludedIdentifiers)),
            PhotoSource(kind: .favorites, count: count(for: .favorites, excluding: excludedIdentifiers)),
            PhotoSource(kind: .untriaged, count: count(for: .all, excluding: excludedIdentifiers))
        ]
    }

    private func count(for kind: PhotoSource.Kind, referenceDate: Date? = nil, excluding excludedIdentifiers: Set<String>) -> Int {
        let result = fetchResult(for: kind, referenceDate: referenceDate)
        guard !excludedIdentifiers.isEmpty else { return result.count }
        var remaining = 0
        result.enumerateObjects { asset, _, _ in
            if !excludedIdentifiers.contains(asset.localIdentifier) {
                remaining += 1
            }
        }
        return remaining
    }

    func fetchReferences(
        for kind: PhotoSource.Kind,
        referenceDate: Date? = nil,
        offset: Int = 0,
        limit: Int? = nil
    ) -> [PhotoAssetReference] {
        let result = fetchResult(for: kind, referenceDate: referenceDate)
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

    func remainingCount(
        for kind: PhotoSource.Kind,
        referenceDate: Date? = nil,
        excluding excludedIdentifiers: Set<String>
    ) -> Int {
        count(for: kind, referenceDate: referenceDate, excluding: excludedIdentifiers)
    }

    private func fetchResult(for kind: PhotoSource.Kind, referenceDate: Date? = nil) -> PHFetchResult<PHAsset> {
        switch kind {
        case .all, .untriaged:
            // `.unknown` means an unknown media type, not “tous les médias”.
            // The nil media type fetch is the PhotoKit API for the complete library.
            return PHAsset.fetchAssets(with: nil)
        case .videos:
            return PHAsset.fetchAssets(with: .video, options: nil)
        case .favorites:
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "favorite == YES")
            return PHAsset.fetchAssets(with: options)
        case .month:
            let calendar = Calendar.current
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate ?? Date())) ?? Date()
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
            return PHAsset.fetchAssets(with: options)
        case .screenshots:
            return assetsInSmartAlbum(.smartAlbumScreenshots)
        case .livePhotos:
            return assetsInSmartAlbum(.smartAlbumLivePhotos)
        }
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

}
