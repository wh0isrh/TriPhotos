import AVKit
import Photos
import SwiftUI

struct PhotoDetailView: View {
    let assetReference: PhotoAssetReference
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if assetReference.mediaType == .video {
                    VideoAssetView(localIdentifier: assetReference.localIdentifier)
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
        }
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

