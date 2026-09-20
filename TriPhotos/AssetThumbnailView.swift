import Photos
import SwiftUI

struct AssetThumbnailView: View {
    let localIdentifier: String
    let contentMode: ContentMode

    @State private var image: UIImage?
    @State private var isUnavailable = false
    @State private var requestID: PHImageRequestID?
    @State private var isVideo = false
    @State private var videoDuration: TimeInterval = 0

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
                    .scaledToFillOrFit(contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isUnavailable {
                Image(systemName: "icloud.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
            if isVideo {
                Label(formatDuration(videoDuration), systemImage: "play.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.68), in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(8)
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
        image = nil
        isUnavailable = false
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
            isUnavailable = true
            return
        }
        isVideo = asset.mediaType == .video
        videoDuration = asset.duration

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        // Autorise uniquement PhotoKit à récupérer un original iCloud pour l’affichage.
        // L’application ne fait aucune requête réseau elle-même.
        options.isNetworkAccessAllowed = true

        requestID = PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 420, height: 420),
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            guard let image else {
                let failed = (info?[PHImageErrorKey] as? Error) != nil || (info?[PHImageResultIsInCloudKey] as? Bool) == true
                if failed { DispatchQueue.main.async { self.isUnavailable = true } }
                return
            }
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

private extension View {
    @ViewBuilder
    func scaledToFillOrFit(_ contentMode: ContentMode) -> some View {
        if contentMode == .fill {
            scaledToFill()
        } else {
            scaledToFit()
        }
    }
}
