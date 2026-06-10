import Foundation

enum NativeQuickSaveMode: String, CaseIterable, Hashable, Identifiable {
    case off
    case favorites
    case on

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            return "Off"
        case .favorites:
            return "Favorites"
        case .on:
            return "On"
        }
    }
}

struct NativeLocalStatus {
    let alias: String
    let shortCode: String
    let address: String
    let port: Int
    let secure: Bool
}
