import AVKit
import Photos
import PhotosUI
import SwiftUI

struct PhotoDetailView: View {
    let assetReference: PhotoAssetReference
    @Environment(\.dismiss) private var dismiss
    @State private var fileSizeText = "Taille indisponible"

    var body: some View {
        NavigationStack {
            Group {
                if assetReference.mediaType == .video {
                    VideoAssetView(localIdentifier: assetReference.localIdentifier)
                } else if assetReference.isLivePhoto {
                    LivePhotoAssetView(localIdentifier: assetReference.localIdentifier)
                } else {
                    HighQualityAssetView(localIdentifier: assetReference.localIdentifier)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .navigationTitle("Aperçu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .safeAreaInset(edge: .bottom) {
                metadata
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.72))
            }
            .task {
                fileSizeText = loadFileSize()
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(assetReference.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? "Date inconnue")
                Spacer()
                if assetReference.mediaType == .video {
                    Text(formatDuration(assetReference.duration))
                }
            }
            .font(.caption)
            .foregroundStyle(.white)
            Text("\(assetReference.pixelWidth) × \(assetReference.pixelHeight) px  ·  \(fileSizeText)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private func loadFileSize() -> String {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetReference.localIdentifier], options: nil).firstObject,
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

private struct HighQualityAssetView: View {
    let localIdentifier: String
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1

    var body: some View {
        Group {
            if let image {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(value, 1), 5)
                                }
                        )
                }
            } else {
                ProgressView().tint(.white)
            }
        }
        .task { load() }
    }

    private func load() {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else { return }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let image else { return }
            DispatchQueue.main.async { self.image = image }
        }
    }
}

private struct LivePhotoAssetView: UIViewRepresentable {
    let localIdentifier: String

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ view: PHLivePhotoView, context: Context) {
        guard view.livePhoto == nil,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else { return }

        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestLivePhoto(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { livePhoto, _ in
            guard let livePhoto else { return }
            DispatchQueue.main.async {
                view.livePhoto = livePhoto
                view.startPlayback(with: .full)
            }
        }
    }
}

private struct VideoAssetView: View {
    let localIdentifier: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView().tint(.white)
            }
        }
        .task { load() }
    }

    private func load() {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else { return }
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset else { return }
            DispatchQueue.main.async { player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset)) }
        }
    }
}
