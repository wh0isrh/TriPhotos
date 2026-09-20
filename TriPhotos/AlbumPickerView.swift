import SwiftUI

struct AlbumPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var albums: [PhotoAlbum] = []
    @State private var newAlbumTitle = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    let onAlbumSelected: (PhotoAlbum) -> Void
    let onFavoriteSelected: () -> Void
    private let service = PhotoAlbumService()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onFavoriteSelected()
                        dismiss()
                    } label: {
                        Label("Ajouter aux favoris", systemImage: "heart.fill")
                    }
                }
                Section("Albums existants") {
                    if albums.isEmpty {
                        Text("Aucun album personnel trouvé.").foregroundStyle(.secondary)
                    } else {
                        ForEach(albums) { album in
                            Button {
                                onAlbumSelected(album)
                                dismiss()
                            } label: {
                                Label(album.title, systemImage: "rectangle.stack")
                            }
                        }
                    }
                }
                Section("Créer un album") {
                    HStack {
                        TextField("Nom de l’album", text: $newAlbumTitle)
                        Button("Créer") { createAlbum() }
                            .disabled(newAlbumTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                    }
                }
            }
            .navigationTitle("Ajouter à…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
            .alert("Albums", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task { albums = service.albums() }
        }
    }

    private func createAlbum() {
        isCreating = true
        service.createAlbum(title: newAlbumTitle) { result in
            isCreating = false
            switch result {
            case .success(let album):
                albums.append(album)
                newAlbumTitle = ""
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

