import Foundation
import Combine
import Photos
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var authorization: PhotoLibraryAuthorization
    @Published private(set) var sources: [PhotoSource] = []
    @Published private(set) var isLoading = false
    @Published var selectedSource: PhotoSource.Kind?

    private let photoLibraryService: PhotoLibraryService
    private var modelContext: ModelContext?

    init(photoLibraryService: PhotoLibraryService = PhotoLibraryService()) {
        self.photoLibraryService = photoLibraryService
        self.authorization = photoLibraryService.authorization()
    }

    func configure(context: ModelContext) {
        modelContext = context
    }

    func load() {
        print("[Photos] Autorisation actuelle: \(authorization)")
        switch authorization {
        case .notDetermined: requestAuthorization()
        case .authorized, .limited: refreshSources()
        case .denied, .restricted: sources = []
        }
    }

    func requestAuthorization() {
        print("[Photos] Demande d’autorisation")
        photoLibraryService.requestAuthorization { [weak self] authorization in
            guard let self else { return }
            self.authorization = authorization
            print("[Photos] Nouvelle autorisation: \(authorization)")
            if authorization == .authorized || authorization == .limited {
                self.refreshSources()
            }
        }
    }

    func refreshSources() {
        guard authorization == .authorized || authorization == .limited else { return }
        isLoading = true
        print("[Photos] Comptage des sources")
        let service = photoLibraryService
        let excluded: Set<String> = {
            guard let context = modelContext else { return [] }
            let decisions = (try? context.fetch(FetchDescriptor<PhotoDecision>())) ?? []
            return Set(decisions.map(\.localIdentifier))
        }()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var sources = service.sources()
            let untriagedCount = max(service.fetchReferences(for: .all).count - excluded.count, 0)
            sources = sources.map { source in
                guard source.kind == .untriaged else { return source }
                return PhotoSource(kind: .untriaged, count: untriagedCount)
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.sources = sources
                self.isLoading = false
                print("[Photos] Sources chargées: \(sources.map(\.count).reduce(0, +)) éléments")
            }
        }
    }
}
