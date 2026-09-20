import SwiftUI
import SwiftData

struct SwipeTriageView: View {
    let sourceKind: PhotoSource.Kind
    let referenceDate: Date?
    let sortOption: PhotoSortOption
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TriageViewModel
    @State private var isAlbumPickerPresented = false
    @State private var detailAsset: PhotoAssetReference?
    @State private var cardOffset: CGSize = .zero

    init(
        sourceKind: PhotoSource.Kind,
        referenceDate: Date? = nil,
        sortOption: PhotoSortOption = .libraryOrder
    ) {
        self.sourceKind = sourceKind
        self.referenceDate = referenceDate
        self.sortOption = sortOption
        _viewModel = StateObject(wrappedValue: TriageViewModel())
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView("Préparation du tri…")
            } else if let asset = viewModel.currentAsset {
                header
                card(for: asset)
                controls
            } else {
                ContentUnavailableView("Tri terminé", systemImage: "checkmark.circle")
                Text("Toutes les photos de cette source ont été parcourues.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Tri")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(
                context: modelContext,
                sourceKind: sourceKind,
                referenceDate: referenceDate,
                sortOption: sortOption
            )
        }
        .sheet(isPresented: $isAlbumPickerPresented) {
            AlbumPickerView(
                onAlbumSelected: { album in viewModel.addCurrentToAlbum(album) },
                onFavoriteSelected: { viewModel.addCurrentToFavorites() }
            )
        }
        .sheet(item: $detailAsset) { asset in
            PhotoDetailView(assetReference: asset)
        }
    }

    private var header: some View {
        HStack {
            Text("\(viewModel.remainingCount) restantes")
                .font(.subheadline.weight(.semibold))
            Text("· \(min(viewModel.currentIndex + 1, max(viewModel.totalCount, 1))) / \(max(viewModel.totalCount, 1))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                viewModel.undo()
            } label: {
                Label("Annuler", systemImage: "arrow.uturn.backward")
            }
            .disabled(viewModel.currentIndex == 0)
        }
    }

    private func card(for asset: PhotoAssetReference) -> some View {
        AssetThumbnailView(localIdentifier: asset.localIdentifier, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(Rectangle())
            .onTapGesture {
                detailAsset = asset
            }
            .offset(cardOffset)
            .rotationEffect(.degrees(Double(cardOffset.width / 24)))
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: cardOffset)
            .highPriorityGesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { value in
                        cardOffset = value.translation
                    }
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        let threshold: CGFloat = 70

                        if abs(horizontal) >= abs(vertical), abs(horizontal) >= threshold {
                            cardOffset = CGSize(width: horizontal > 0 ? 500 : -500, height: 0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                if horizontal < 0 {
                                    viewModel.markCurrentForDeletion()
                                } else {
                                    viewModel.keepCurrent()
                                }
                                cardOffset = .zero
                            }
                        } else if abs(vertical) > abs(horizontal), abs(vertical) >= threshold {
                            // Les deux directions verticales ouvrent le choix album/favori.
                            // Cela rend le geste utilisable dans les deux sens avec une main.
                            cardOffset = CGSize(width: 0, height: vertical > 0 ? 500 : -500)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                isAlbumPickerPresented = true
                                cardOffset = .zero
                            }
                        } else {
                            cardOffset = .zero
                        }
                    }
            )
            .overlay(alignment: .bottom) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "Date inconnue")
                    Text(asset.fileSizeText)
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .padding()
            }
    }

    private var controls: some View {
        HStack(spacing: 22) {
            actionButton(title: "Supprimer", icon: "trash", color: .red) {
                viewModel.markCurrentForDeletion()
            }
            actionButton(title: "Garder", icon: "checkmark", color: .green) {
                viewModel.keepCurrent()
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
}
