import Photos
import SwiftData
import SwiftUI

@MainActor
final class DeletionReviewViewModel: ObservableObject {
    @Published private(set) var identifiers: [String] = []
    @Published private(set) var selectedIdentifiers: Set<String> = []
    @Published private(set) var isProcessing = false
    @Published var message: String?

    private var modelContext: ModelContext?

    func configure(context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        reload()
    }

    func reload() {
        guard let context = modelContext else { return }
        let decisions = (try? context.fetch(FetchDescriptor<PhotoDecision>())) ?? []
        identifiers = decisions
            .filter { $0.actionRawValue == PhotoDecisionAction.deletePending.rawValue }
            .map(\.localIdentifier)
        selectedIdentifiers = Set(identifiers)
        print("[Suppression] File chargée: \(identifiers.count) photos")
    }

    func toggle(_ identifier: String) {
        if selectedIdentifiers.contains(identifier) {
            selectedIdentifiers.remove(identifier)
        } else {
            selectedIdentifiers.insert(identifier)
        }
    }

    func deleteSelected(simulation: Bool) {
        guard !selectedIdentifiers.isEmpty else {
            message = "Sélectionnez au moins une photo."
            return
        }

        let selected = selectedIdentifiers
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(selected), options: nil)
        guard assets.count > 0 else {
            message = "Les photos sélectionnées ne sont plus accessibles."
            return
        }

        if simulation {
            print("[Suppression] SIMULATION: aucune suppression réelle")
            message = "Simulation terminée : aucune photo n’a été supprimée."
            return
        }

        isProcessing = true
        print("[Suppression] Demande de suppression groupée: \(assets.count) photos")
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isProcessing = false
                if success {
                    self.removeDecisions(for: selected)
                    self.message = "\(selected.count) photo(s) déplacée(s) dans Supprimés récemment."
                    self.reload()
                    print("[Suppression] Suppression groupée réussie")
                } else {
                    self.message = error?.localizedDescription ?? "La suppression a échoué."
                    print("[Suppression] Échec: \(error?.localizedDescription ?? "inconnu")")
                }
            }
        }
    }

    private func removeDecisions(for identifiers: Set<String>) {
        guard let context = modelContext else { return }
        let decisions = (try? context.fetch(FetchDescriptor<PhotoDecision>())) ?? []
        for decision in decisions where identifiers.contains(decision.localIdentifier) {
            context.delete(decision)
        }
        try? context.save()
    }
}

struct DeletionReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("simulationMode") private var simulationMode = true
    @StateObject private var viewModel = DeletionReviewViewModel()
    @State private var isConfirmationPresented = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 3)]

    var body: some View {
        VStack(spacing: 0) {
            Toggle("Mode simulation (recommandé)", isOn: $simulationMode)
                .padding()
            Text("Les photos supprimées restent récupérables dans « Supprimés récemment » pendant 30 jours.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)

            if viewModel.identifiers.isEmpty {
                ContentUnavailableView("File vide", systemImage: "checkmark.circle")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.identifiers, id: \.self) { identifier in
                            Button {
                                viewModel.toggle(identifier)
                            } label: {
                                AssetThumbnailView(localIdentifier: identifier)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: viewModel.selectedIdentifiers.contains(identifier) ? "checkmark.circle.fill" : "circle")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .blue)
                                            .padding(8)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("À supprimer")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Supprimer") {
                    isConfirmationPresented = true
                }
                .disabled(viewModel.selectedIdentifiers.isEmpty || viewModel.isProcessing)
            }
        }
        .confirmationDialog(
            simulationMode ? "Lancer la simulation ?" : "Supprimer les photos ?",
            isPresented: $isConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(simulationMode ? "Simuler" : "Supprimer", role: simulationMode ? nil : .destructive) {
                viewModel.deleteSelected(simulation: simulationMode)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text(simulationMode ? "Aucune photo ne sera modifiée." : "La suppression sera groupée en une seule opération iOS.")
        }
        .alert("Résultat", isPresented: Binding(
            get: { viewModel.message != nil },
            set: { if !$0 { viewModel.message = nil } }
        )) {
            Button("OK") { viewModel.message = nil }
        } message: {
            Text(viewModel.message ?? "")
        }
        .task { viewModel.configure(context: modelContext) }
    }
}

