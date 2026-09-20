import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("TriPhotos")
                        .font(.largeTitle.bold())
                    Text("Votre photothèque reste sur votre iPhone.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Étape 0 validée : le projet démarre correctement. L’accès à vos photos sera ajouté à l’étape suivante.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("TriPhotos")
        }
    }
}

#Preview {
    ContentView()
}

