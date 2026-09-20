import Foundation
import Combine
import Photos

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var authorization: PhotoLibraryAuthorization
    @Published private(set) var sources: [PhotoSource] = []
    @Published private(set) var isLoading = false
    @Published var selectedSource: PhotoSource.Kind?

    private let photoLibraryService: PhotoLibraryService

    init(photoLibraryService: PhotoLibraryService = PhotoLibraryService()) {
        self.photoLibraryService = photoLibraryService
        self.authorization = photoLibraryService.authorization()
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let sources = service.sources()
            DispatchQueue.main.async {
                guard let self else { return }
                self.sources = sources
                self.isLoading = false
                print("[Photos] Sources chargées: \(sources.map(\.count).reduce(0, +)) éléments")
            }
        }
    }
}
