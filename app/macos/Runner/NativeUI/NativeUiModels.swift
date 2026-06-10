import Foundation

enum NativeReceiveAvailability: String, Hashable {
    case ready
    case offline
    case noNetwork

    var title: String {
        switch self {
        case .ready:
            return "Receiving as"
        case .offline:
            return "Offline"
        case .noNetwork:
            return "No Network"
        }
    }

    var symbolName: String {
        switch self {
        case .ready:
            return "circle.fill"
        case .offline:
            return "pause.circle.fill"
        case .noNetwork:
            return "wifi.exclamationmark"
        }
    }
}

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

struct NativeReceiveState {
    var availability: NativeReceiveAvailability
    var localStatus: NativeLocalStatus
    var quickSaveMode: NativeQuickSaveMode
    var activity: NativeReceiveActivity

    static let preview = NativeReceiveState(
        availability: .ready,
        localStatus: NativeLocalStatus(
            alias: "Kind Cherry",
            platformName: "macOS",
            platformDetail: "MacBook Pro",
            platformSymbolName: "macbook",
            localAddresses: [
                "192.168.1.16",
                "192.168.1.1",
            ],
            port: 53317,
            secure: false
        ),
        quickSaveMode: .favorites,
        activity: .idle
    )

    static let offlinePreview = NativeReceiveState(
        availability: .offline,
        localStatus: NativeLocalStatus(
            alias: "Kind Cherry",
            platformName: "macOS",
            platformDetail: "MacBook Pro",
            platformSymbolName: "macbook",
            localAddresses: [],
            port: 53317,
            secure: false
        ),
        quickSaveMode: .off,
        activity: .idle
    )

    static let noNetworkPreview = NativeReceiveState(
        availability: .noNetwork,
        localStatus: NativeLocalStatus(
            alias: "Kind Cherry",
            platformName: "macOS",
            platformDetail: "MacBook Pro",
            platformSymbolName: "macbook",
            localAddresses: [],
            port: 53317,
            secure: false
        ),
        quickSaveMode: .favorites,
        activity: .idle
    )

    static let incomingPreview = NativeReceiveState(
        availability: .ready,
        localStatus: preview.localStatus,
        quickSaveMode: .off,
        activity: .incoming(.preview)
    )

    static let receivingPreview = NativeReceiveState(
        availability: .ready,
        localStatus: preview.localStatus,
        quickSaveMode: .favorites,
        activity: .receiving(.preview)
    )

    static let completedPreview = NativeReceiveState(
        availability: .ready,
        localStatus: preview.localStatus,
        quickSaveMode: .favorites,
        activity: .completed(.preview)
    )
}

enum NativeReceiveActivity: Hashable {
    case idle
    case incoming(NativeIncomingReceiveRequest)
    case receiving(NativeActiveReceiveTransfer)
    case completed(NativeCompletedReceiveTransfer)
}

struct NativeRemoteDevice: Hashable {
    let alias: String
    let platformName: String
    let platformDetail: String
    let platformSymbolName: String
    let localId: String?
    let isFavorite: Bool

    static let preview = NativeRemoteDevice(
        alias: "Daniel's iPhone",
        platformName: "iOS",
        platformDetail: "iPhone 15 Pro",
        platformSymbolName: "iphone",
        localId: "#86",
        isFavorite: true
    )
}

struct NativeReceiveFile: Hashable, Identifiable {
    let id: String
    let name: String
    let detail: String

    static let previews = [
        NativeReceiveFile(id: "photo", name: "IMG_4281.HEIC", detail: "2.4 MB"),
        NativeReceiveFile(id: "notes", name: "Weekend Notes.md", detail: "42 KB"),
        NativeReceiveFile(id: "archive", name: "Design References.zip", detail: "18.4 MB"),
    ]
}

struct NativeIncomingReceiveRequest: Hashable {
    let sender: NativeRemoteDevice
    let files: [NativeReceiveFile]
    let totalSize: String
    let message: String?

    var fileCountText: String {
        files.count == 1 ? "1 item" : "\(files.count) items"
    }

    static let preview = NativeIncomingReceiveRequest(
        sender: .preview,
        files: NativeReceiveFile.previews,
        totalSize: "20.9 MB",
        message: nil
    )
}

struct NativeActiveReceiveTransfer: Hashable {
    let sender: NativeRemoteDevice
    let files: [NativeReceiveFile]
    let currentFileName: String
    let progress: Double
    let savedAutomatically: Bool

    var progressText: String {
        "\(Int(progress * 100))%"
    }

    static let preview = NativeActiveReceiveTransfer(
        sender: .preview,
        files: NativeReceiveFile.previews,
        currentFileName: "Design References.zip",
        progress: 0.42,
        savedAutomatically: true
    )
}

struct NativeCompletedReceiveTransfer: Hashable {
    let sender: NativeRemoteDevice
    let files: [NativeReceiveFile]
    let totalSize: String

    var summaryText: String {
        files.count == 1 ? "Received 1 item" : "Received \(files.count) items"
    }

    static let preview = NativeCompletedReceiveTransfer(
        sender: .preview,
        files: NativeReceiveFile.previews,
        totalSize: "20.9 MB"
    )
}
