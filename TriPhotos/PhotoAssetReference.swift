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
