import Foundation

enum PhotoSortOption: String, CaseIterable, Identifiable {
    case libraryOrder
    case largestFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .libraryOrder: return "Ordre de la photothèque"
        case .largestFirst: return "Plus volumineuses d’abord"
        }
    }

    var icon: String {
        switch self {
        case .libraryOrder: return "arrow.up.arrow.down"
        case .largestFirst: return "externaldrive.fill"
        }
    }
}
