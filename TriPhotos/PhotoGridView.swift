import Photos
import SwiftData
import SwiftUI

@MainActor
final class PhotoGridViewModel: ObservableObject {
    @Published private(set) var assets: [PhotoAssetReference] = []
    @Published private(set) var isLoading = false

    private let sourceKind: PhotoSource.Kind
    private let service = PhotoLibraryService()
    private var modelContext: ModelContext?
    private let pageSize = 120
    private var nextOffset = 0
    private var hasMore = true
    private var loadedSort: PhotoSortOption = .libraryOrder
    private var sortedReferences: [PhotoAssetReference]?

    init(sourceKind: PhotoSource.Kind) {
        self.sourceKind = sourceKind
    }

    func configure(context: ModelContext) {
        modelContext = context
    }

    func load(referenceDate: Date? = nil, sort: PhotoSortOption = .libraryOrder, force: Bool = false) {
        guard !isLoading else { return }
        guard force || assets.isEmpty || loadedSort != sort else { return }
        loadedSort = sort
        assets = []
        nextOffset = 0
        hasMore = true
        sortedReferences = nil
        loadMore(referenceDate: referenceDate)
    }

    func loadMore(referenceDate: Date? = nil) {
        guard !isLoading, hasMore else { return }
        isLoading = true
        print("[Photos] Chargement de la grille: \(sourceKind.rawValue)")
        let service = service
        let selectedSource = sourceKind
        let pageOffset = nextOffset
        let pageSize = pageSize
        let selectedSort = loadedSort
        let cachedSortedReferences = sortedReferences
        let excludedIdentifiers: Set<String> = {
            guard selectedSource == .untriaged, let context = modelContext else { return [] }
            let decisions = (try? context.fetch(FetchDescriptor<PhotoDecision>())) ?? []
            return Set(decisions.map(\.localIdentifier))
        }()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var sortedForCache: [PhotoAssetReference]?
            let rawFetched: [PhotoAssetReference]
            if selectedSort == .largestFirst {
                let sorted = cachedSortedReferences ?? service.fetchReferences(
                    for: selectedSource,
                    referenceDate: referenceDate,
                    sort: selectedSort
                )
                sortedForCache = cachedSortedReferences == nil ? sorted : nil
                rawFetched = Array(sorted.dropFirst(pageOffset).prefix(pageSize))
            } else {
                sortedForCache = nil
                rawFetched = service.fetchReferences(
                    for: selectedSource,
                    referenceDate: referenceDate,
                    offset: pageOffset,
                    limit: pageSize
                )
            }
            let reachedEnd = rawFetched.count < pageSize
            var fetched = rawFetched
            if selectedSource == .untriaged {
                fetched = fetched.filter { !excludedIdentifiers.contains($0.localIdentifier) }
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.assets.append(contentsOf: fetched)
                if let sortedForCache {
                    self.sortedReferences = sortedForCache
                }
                self.nextOffset = pageOffset + pageSize
                self.hasMore = !reachedEnd
                self.isLoading = false
                print("[Photos] Grille chargée: \(fetched.count) éléments")
                if fetched.isEmpty && !reachedEnd {
                    self.loadMore(referenceDate: referenceDate)
                }
            }
        }
    }
}

struct PhotoGridView: View {
    let sourceKind: PhotoSource.Kind
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: PhotoGridViewModel
    @State private var selectedMonthDate = Date()
    @State private var selectedSort: PhotoSortOption = .libraryOrder

    init(sourceKind: PhotoSource.Kind) {
        self.sourceKind = sourceKind
        _viewModel = StateObject(wrappedValue: PhotoGridViewModel(sourceKind: sourceKind))
    }

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 3)]

    var body: some View {
        Group {
            if sourceKind == .month {
                VStack(spacing: 8) {
                    DatePicker("Mois à afficher", selection: $selectedMonthDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                    gridContent
                }
            } else {
                gridContent
            }
        }
        .navigationTitle(sourceKind.title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Trier par", selection: $selectedSort) {
                        ForEach(PhotoSortOption.allCases) { option in
                            Label(option.title, systemImage: option.icon).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: selectedSort.icon)
                }
                .accessibilityLabel("Ordre de tri")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Trier") {
                    SwipeTriageView(
                        sourceKind: sourceKind,
                        referenceDate: sourceKind == .month ? selectedMonthDate : nil,
                        sortOption: selectedSort
                    )
                }
                .disabled(viewModel.assets.isEmpty)
            }
        }
        .task {
            viewModel.configure(context: modelContext)
            viewModel.load(referenceDate: sourceKind == .month ? selectedMonthDate : nil, sort: selectedSort)
        }
        .onChange(of: selectedSort) { _, newSort in
            viewModel.load(
                referenceDate: sourceKind == .month ? selectedMonthDate : nil,
                sort: newSort,
                force: true
            )
        }
        .onChange(of: selectedMonthDate) { _, newDate in
            guard sourceKind == .month else { return }
            viewModel.load(referenceDate: newDate, force: true)
        }
    }

    @ViewBuilder
    private var gridContent: some View {
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
                                .onAppear {
                                    if asset.id == viewModel.assets.last?.id {
                                        viewModel.loadMore(referenceDate: sourceKind == .month ? selectedMonthDate : nil)
                                    }
                                }
                        }
                    }
                }
            }
    }
}
