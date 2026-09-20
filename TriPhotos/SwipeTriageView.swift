import SwiftUI
import SwiftData

struct SwipeTriageView: View {
    let sourceKind: PhotoSource.Kind
    let referenceDate: Date?
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TriageViewModel
    @State private var isAlbumPickerPresented = false
    @State private var detailAsset: PhotoAssetReference?

    init(sourceKind: PhotoSource.Kind, referenceDate: Date? = nil) {
        self.sourceKind = sourceKind
        self.referenceDate = referenceDate
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
            viewModel.configure(context: modelContext, sourceKind: sourceKind, referenceDate: referenceDate)
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
            Text("· \(viewModel.currentIndex + 1) / \(viewModel.assets.count)")
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
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -60 {
                            viewModel.markCurrentForDeletion()
                        } else if value.translation.width > 60 {
                            viewModel.keepCurrent()
                        } else if value.translation.height < -60 {
                            isAlbumPickerPresented = true
                        }
                    }
            )
            .overlay(alignment: .bottom) {
                Text(asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "Date inconnue")
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
