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

    var explanation: String {
        switch self {
        case .off:
            return "Ask before saving incoming files."
        case .favorites:
            return "Automatically save files from favorite devices."
        case .on:
            return "Automatically save files from any device."
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
