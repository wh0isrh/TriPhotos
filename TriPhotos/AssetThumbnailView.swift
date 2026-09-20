import Photos
import SwiftUI

struct AssetThumbnailView: View {
    let localIdentifier: String
    let contentMode: ContentMode

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    init(localIdentifier: String, contentMode: ContentMode = .fill) {
        self.localIdentifier = localIdentifier
        self.contentMode = contentMode
    }

    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ProgressView()
            }
        }
        .clipped()
        .task(id: localIdentifier) {
            loadImage()
        }
        .onDisappear {
            if let requestID {
                PHCachingImageManager.default().cancelImageRequest(requestID)
            }
        }
    }

    private func loadImage() {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        requestID = PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 420, height: 420),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            guard let image else { return }
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}

