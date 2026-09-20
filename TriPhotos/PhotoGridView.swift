import Photos
import SwiftUI

@MainActor
final class PhotoGridViewModel: ObservableObject {
    @Published private(set) var assets: [PhotoAssetReference] = []
    @Published private(set) var isLoading = false

    private let sourceKind: PhotoSource.Kind
    private let service = PhotoLibraryService()

    init(sourceKind: PhotoSource.Kind) {
        self.sourceKind = sourceKind
    }

    func load() {
        guard !isLoading, assets.isEmpty else { return }
        isLoading = true
        print("[Photos] Chargement de la grille: \(sourceKind.rawValue)")
        let service = service
        let selectedSource = sourceKind

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetched = service.fetchReferences(for: selectedSource)
            DispatchQueue.main.async {
                guard let self else { return }
                self.assets = fetched
                self.isLoading = false
                print("[Photos] Grille chargée: \(fetched.count) éléments")
            }
        }
    }
}

struct PhotoGridView: View {
    let sourceKind: PhotoSource.Kind
    @StateObject private var viewModel: PhotoGridViewModel

    init(sourceKind: PhotoSource.Kind) {
        self.sourceKind = sourceKind
        _viewModel = StateObject(wrappedValue: PhotoGridViewModel(sourceKind: sourceKind))
    }

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 3)]

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Chargement des miniatures…")
            } else if viewModel.assets.isEmpty {
                ContentUnavailableView("Aucune photo", systemImage: "photo.on.rectangle")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.assets) { asset in
                            AssetThumbnailView(localIdentifier: asset.localIdentifier)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .navigationTitle(sourceKind.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Trier") {
                    SwipeTriageView(sourceKind: sourceKind)
                }
                .disabled(viewModel.assets.isEmpty)
            }
        }
        .task { viewModel.load() }
    }
}
