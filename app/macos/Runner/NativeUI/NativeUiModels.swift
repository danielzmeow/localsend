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

    var symbolName: String {
        switch self {
        case .off:
            return "xmark"
        case .favorites:
            return "star.fill"
        case .on:
            return "checkmark"
        }
    }

    var description: String {
        switch self {
        case .off:
            return "Files will not be saved automatically. You'll be prompted before each transfer."
        case .favorites:
            return "Files from favorite devices are saved automatically without a prompt."
        case .on:
            return "All incoming files are saved automatically without any confirmation."
        }
    }
}

struct NativeLocalStatus {
    let alias: String
    let platformName: String
    let platformDetail: String
    let platformSymbolName: String
    let localAddresses: [String]
    let port: Int
    let secure: Bool

    var localIds: [String] {
        localAddresses.map { address in
            let suffix = address.split(separator: ".").last.map(String.init) ?? address
            return "#\(suffix)"
        }
    }

    var primaryAddress: String {
        localAddresses.first ?? "-"
    }
}
