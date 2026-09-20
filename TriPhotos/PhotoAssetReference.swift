import Photos

struct PhotoAssetReference: Identifiable, Hashable {
    let localIdentifier: String
    let mediaType: PHAssetMediaType
    let isLivePhoto: Bool
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval

    var id: String { localIdentifier }

    var fileSizeText: String {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject,
              let resource = PHAssetResource.assetResources(for: asset).first,
              let rawSize = resource.value(forKey: "fileSize") as? NSNumber else {
            return "Taille indisponible"
        }

        let bytes = rawSize.int64Value
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
    }
}
