import Combine
import Foundation
import Photos
import SwiftData
import UIKit

@MainActor
final class TriageViewModel: ObservableObject {
    @Published private(set) var assets: [PhotoAssetReference] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var isLoading = false
    @Published private(set) var lastAction: PhotoDecisionAction?

    private var modelContext: ModelContext?
    private var sourceKind: PhotoSource.Kind = .all
    private var referenceDate: Date?
    private var undoStack: [String] = []
    private let service = PhotoLibraryService()
    private let albumService = PhotoAlbumService()
    private let imageManager = PHCachingImageManager()
    private let pageSize = 60
    private var nextOffset = 0
    private var hasMore = true
    private var didLoad = false

    var currentAsset: PhotoAssetReference? {
        guard assets.indices.contains(currentIndex) else { return nil }
        return assets[currentIndex]
    }

    var remainingCount: Int {
        max(assets.count - currentIndex, 0)
    }

    func configure(context: ModelContext, sourceKind: PhotoSource.Kind, referenceDate: Date? = nil) {
        guard modelContext == nil else { return }
        modelContext = context
        self.sourceKind = sourceKind
        self.referenceDate = referenceDate
        load()
    }

    func load() {
        guard !isLoading, !didLoad else { return }
        didLoad = true
        nextOffset = 0
        hasMore = true
        loadMore()
    }

    private func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        let excludedIdentifiers = excludedIdentifiers()
        let selectedSource = sourceKind
        let selectedDate = referenceDate
        let service = service
        let pageOffset = nextOffset
        let pageSize = pageSize
        print("[Tri] Chargement des photos non triées: \(selectedSource.rawValue)")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let rawFetched = service.fetchReferences(
                for: selectedSource,
                referenceDate: selectedDate,
                offset: pageOffset,
                limit: pageSize
            )
            let reachedEnd = rawFetched.count < pageSize
            let fetched = rawFetched
                .filter { !excludedIdentifiers.contains($0.localIdentifier) }
            DispatchQueue.main.async {
                guard let self else { return }
                self.assets.append(contentsOf: fetched)
                self.nextOffset = pageOffset + pageSize
                self.hasMore = !reachedEnd
                self.isLoading = false
                self.preheatNextAssets()
                print("[Tri] Photos disponibles: \(fetched.count)")
            }
        }
    }

    func keepCurrent() {
        apply(.kept)
    }

    func markCurrentForDeletion() {
        apply(.deletePending)
    }

    func addCurrentToAlbum(_ album: PhotoAlbum) {
        guard let asset = currentAsset else { return }
        albumService.addAsset(localIdentifier: asset.localIdentifier, to: album) { [weak self] result in
            switch result {
            case .success:
                print("[Tri] Photo ajoutée à l’album: \(album.title)")
                self?.keepCurrent()
            case .failure(let error):
                print("[Tri] Erreur album: \(error.localizedDescription)")
            }
        }
    }

    func addCurrentToFavorites() {
        guard let asset = currentAsset else { return }
        albumService.markFavorite(localIdentifier: asset.localIdentifier) { [weak self] result in
            switch result {
            case .success:
                print("[Tri] Photo ajoutée aux favoris")
                self?.keepCurrent()
            case .failure(let error):
                print("[Tri] Erreur favori: \(error.localizedDescription)")
            }
        }
    }

    func undo() {
        guard let identifier = undoStack.popLast(), let context = modelContext else { return }
        let decisions = (try? context.fetch(FetchDescriptor<PhotoDecision>())) ?? []
        for decision in decisions where decision.localIdentifier == identifier {
            context.delete(decision)
        }
        try? context.save()
        currentIndex = max(currentIndex - 1, 0)
        lastAction = nil
        print("[Tri] Annulation: \(identifier)")
    }

    private func apply(_ action: PhotoDecisionAction) {
        guard let asset = currentAsset, let context = modelContext else { return }
        let decision = PhotoDecision(
            localIdentifier: asset.localIdentifier,
            actionRawValue: action.rawValue,
            sourceRawValue: sourceKind.rawValue
        )
        context.insert(decision)
        do {
            try context.save()
            undoStack.append(asset.localIdentifier)
            lastAction = action
            currentIndex += 1
            UIImpactFeedbackGenerator(style: action == .deletePending ? .medium : .light).impactOccurred()
            preheatNextAssets()
            if currentIndex >= assets.count - 5 {
                loadMore()
            }
            print("[Tri] \(action.rawValue): \(asset.localIdentifier)")
        } catch {
            print("[Tri] Erreur de sauvegarde: \(error.localizedDescription)")
        }
    }

    private func excludedIdentifiers() -> Set<String> {
        guard let context = modelContext else { return [] }
        let decisions = (try? context.fetch(FetchDescriptor<PhotoDecision>())) ?? []
        return Set(decisions.map(\.localIdentifier))
    }

    private func preheatNextAssets() {
        let next = Array(assets.dropFirst(currentIndex).prefix(3))
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: next.map(\.localIdentifier), options: nil)
        var assetsToCache: [PHAsset] = []
        fetched.enumerateObjects { asset, _, _ in assetsToCache.append(asset) }
        guard !assetsToCache.isEmpty else { return }
        imageManager.startCachingImages(
            for: assetsToCache,
            targetSize: CGSize(width: 900, height: 900),
            contentMode: .aspectFit,
            options: nil
        )
    }
}
