import Foundation

final class NativeUiStore: ObservableObject {
    @Published var selectedSection: NativeSection = .receive
    @Published var localStatus = NativeLocalStatus(
        alias: "Daniel's MacBook",
        address: "192.168.1.42",
        port: 53317,
        secure: false
    )
    @Published var devices: [NativeDevice] = [
        NativeDevice(
            id: "iphone",
            alias: "iPhone",
            model: "iPhone 15 Pro",
            address: "192.168.1.86",
            secure: false,
            online: true
        ),
        NativeDevice(
            id: "studio",
            alias: "Studio Mac",
            model: "macOS",
            address: "192.168.1.19",
            secure: true,
            online: true
        ),
        NativeDevice(
            id: "ipad",
            alias: "iPad",
            model: "iPadOS",
            address: "192.168.1.58",
            secure: false,
            online: false
        ),
    ]
    @Published var queuedFiles: [NativeQueuedFile] = [
        NativeQueuedFile(id: "one", name: "Weekend Notes.md", size: "42 KB", kind: "Text"),
        NativeQueuedFile(id: "two", name: "Design References.zip", size: "18.4 MB", kind: "Archive"),
    ]
    @Published var transfers: [NativeTransferItem] = [
        NativeTransferItem(
            id: "send-one",
            title: "Design References.zip",
            detail: "Sending to iPhone",
            progress: 0.62,
            status: .sending
        ),
        NativeTransferItem(
            id: "receive-one",
            title: "Screenshot.png",
            detail: "Receiving from Studio Mac",
            progress: 0.28,
            status: .receiving
        ),
    ]
}

enum NativeSection: String, CaseIterable, Identifiable {
    case receive = "Receive"
    case send = "Send"
    case settings = "Settings"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .receive:
            return "tray.and.arrow.down"
        case .send:
            return "paperplane"
        case .settings:
            return "gearshape"
        }
    }
}
