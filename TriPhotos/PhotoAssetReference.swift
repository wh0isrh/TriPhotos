import Photos

struct PhotoAssetReference: Identifiable, Hashable {
    let localIdentifier: String
    let mediaType: PHAssetMediaType
    let isLivePhoto: Bool
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    let fileSizeBytes: Int64?

    var id: String { localIdentifier }

    var fileSizeText: String {
        guard let bytes = fileSizeBytes, bytes > 0 else {
            return "Taille indisponible"
        }

        if bytes >= 1_000_000_000 {
            return String(format: "%.1f Go", Double(bytes) / 1_000_000_000)
        }
        if bytes >= 1_000_000 {
            return String(format: "%.1f Mo", Double(bytes) / 1_000_000)
        }
        return String(format: "%.0f Ko", Double(bytes) / 1_000)
    }

    init(asset: PHAsset) {
        localIdentifier = asset.localIdentifier
        mediaType = asset.mediaType
        isLivePhoto = asset.mediaSubtypes.contains(.photoLive)
        creationDate = asset.creationDate
        pixelWidth = asset.pixelWidth
        pixelHeight = asset.pixelHeight
        duration = asset.duration
        fileSizeBytes = PHAssetResource.assetResources(for: asset)
            .compactMap { ($0.value(forKey: "fileSize") as? NSNumber)?.int64Value }
            .first(where: { $0 > 0 })
    }
}
