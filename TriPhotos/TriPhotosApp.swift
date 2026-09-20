import SwiftUI
import SwiftData

@main
struct TriPhotosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PhotoDecision.self)
    }
}
