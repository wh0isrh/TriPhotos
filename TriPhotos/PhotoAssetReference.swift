import Photos

struct PhotoAssetReference: Identifiable, Hashable {
    let localIdentifier: String
    let mediaType: PHAssetMediaType
    let isLivePhoto: Bool
    let creationDate: Date?

    var id: String { localIdentifier }

    init(asset: PHAsset) {
        localIdentifier = asset.localIdentifier
        mediaType = asset.mediaType
        isLivePhoto = asset.mediaSubtypes.contains(.photoLive)
        creationDate = asset.creationDate
    }
}
