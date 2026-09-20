import Photos
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.authorization {
                case .notDetermined:
                    permissionView(title: "Accès à votre photothèque", message: "TriPhotos a besoin de votre autorisation pour afficher et trier vos photos sur cet iPhone.", buttonTitle: "Autoriser les photos") {
                        viewModel.requestAuthorization()
                    }
                case .denied, .restricted:
                    permissionView(title: "Accès refusé", message: "Autorisez l’accès aux photos dans Réglages pour utiliser TriPhotos.", buttonTitle: "Ouvrir Réglages") {
                        openSettings()
                    }
                case .authorized, .limited:
                    sourceList
                }
            }
            .navigationTitle("TriPhotos")
        }
        .task { viewModel.load() }
    }

    private var sourceList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choisissez une source").font(.title2.bold())
                    Text("Les compteurs sont calculés localement sur votre iPhone.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("À trier") {
                if viewModel.isLoading {
                    ProgressView("Comptage en cours…")
                } else if viewModel.sources.isEmpty {
                    ContentUnavailableView("Aucune photo accessible", systemImage: "photo.on.rectangle")
                } else {
                    ForEach(viewModel.sources) { source in
                        NavigationLink {
                            PhotoGridView(sourceKind: source.kind)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: source.kind.icon).frame(width: 28).foregroundStyle(.blue)
                                Text(source.kind.title)
                                Spacer()
                                Text(source.count.formatted()).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Actions") {
                NavigationLink {
                    DeletionReviewView()
                } label: {
                    Label("File de suppression", systemImage: "trash")
                }
            }
        }
        .refreshable { viewModel.refreshSources() }
    }

    private func permissionView(title: String, message: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "photo.on.rectangle.angled")
        } description: {
            Text(message)
        } actions: {
            Button(buttonTitle, action: action).buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}
