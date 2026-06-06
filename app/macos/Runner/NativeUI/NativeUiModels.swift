import Foundation

enum NativeTransferStatus: String {
    case idle = "Idle"
    case waiting = "Waiting"
    case sending = "Sending"
    case receiving = "Receiving"
    case finished = "Finished"
}

struct NativeLocalStatus {
    let alias: String
    let address: String
    let port: Int
    let secure: Bool
}

struct NativeDevice: Identifiable {
    let id: String
    let alias: String
    let model: String
    let address: String
    let secure: Bool
    let online: Bool
}

struct NativeQueuedFile: Identifiable {
    let id: String
    let name: String
    let size: String
    let kind: String
}

struct NativeTransferItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let progress: Double
    let status: NativeTransferStatus
}
