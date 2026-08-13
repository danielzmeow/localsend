import Foundation

@MainActor
final class NativeUiStore: ObservableObject {
    @Published var selectedSection: NativeSection? = .receive
    @Published private(set) var snapshot: NativeUiSnapshot?
    @Published private(set) var bridgeErrorMessage: String?
    @Published private(set) var refreshErrorMessage: String?
    @Published private(set) var isRefreshCommandRunning = false
    @Published private(set) var selectionErrorMessage: String?
    @Published private(set) var isSelectionCommandRunning = false

    private var latestRevision = 0
    private var requestedInitialDeviceRefresh = false

    init(snapshot: NativeUiSnapshot? = nil) {
        self.snapshot = snapshot
        latestRevision = snapshot?.revision ?? 0
    }

    var receiveState: NativeReceiveState? {
        snapshot.map(NativeReceiveState.live)
    }

    var devices: [NativeUiDeviceSnapshot] {
        snapshot?.devices ?? []
    }

    var localIps: [String] {
        snapshot?.localIps ?? []
    }

    var selectedFiles: [NativeUiFileSnapshot] {
        snapshot?.selectedFiles ?? []
    }

    var selectedFileCount: Int {
        selectedFiles.count
    }

    var selectedFileSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }

    var formattedSelectedFileSize: String {
        ByteCountFormatter.string(fromByteCount: selectedFileSize, countStyle: .file)
    }

    var isScanning: Bool {
        isRefreshCommandRunning || snapshot?.discovery.scanning == true
    }

    var canRefreshDevices: Bool {
        snapshot != nil && !localIps.isEmpty && !isScanning
    }

    func apply(snapshot: NativeUiSnapshot) {
        guard snapshot.revision > latestRevision else {
            return
        }
        latestRevision = snapshot.revision
        self.snapshot = snapshot
        bridgeErrorMessage = nil
    }

    func reportBridgeError(_ message: String) {
        bridgeErrorMessage = message
    }

    func beginRefreshingDevices() {
        guard !isRefreshCommandRunning else {
            return
        }
        isRefreshCommandRunning = true
        refreshErrorMessage = nil
    }

    func finishRefreshingDevices(errorMessage: String?) {
        isRefreshCommandRunning = false
        refreshErrorMessage = errorMessage
    }

    func beginSelectionCommand() {
        isSelectionCommandRunning = true
        selectionErrorMessage = nil
    }

    func finishSelectionCommand(errorMessage: String?) {
        isSelectionCommandRunning = false
        selectionErrorMessage = errorMessage
    }

    func requestInitialDeviceRefresh(using refresh: () -> Void) {
        guard !requestedInitialDeviceRefresh,
              snapshot != nil,
              devices.isEmpty,
              !localIps.isEmpty else {
            return
        }
        requestedInitialDeviceRefresh = true
        refresh()
    }
}

extension NativeUiStore {
    static var receivePreview: NativeUiStore {
        NativeUiStore(snapshot: previewSnapshot())
    }

    static var noNetworkPreview: NativeUiStore {
        NativeUiStore(snapshot: previewSnapshot(localIps: []))
    }

    static var sendPreview: NativeUiStore {
        let store = NativeUiStore(
            snapshot: previewSnapshot(devices: [
                NativeUiDeviceSnapshot(
                    id: "iphone",
                    alias: "Daniel's iPhone",
                    ip: "192.168.1.86",
                    port: 53317,
                    https: false,
                    fingerprint: "preview",
                    deviceModel: "iPhone 15 Pro",
                    deviceType: "mobile",
                    download: false,
                    isFavorite: true
                ),
            ])
        )
        store.selectedSection = .send
        return store
    }

    private static func previewSnapshot(
        localIps: [String] = ["192.168.1.16"],
        devices: [NativeUiDeviceSnapshot] = []
    ) -> NativeUiSnapshot {
        NativeUiSnapshot(
            schemaVersion: NativeUiSnapshot.supportedSchemaVersion,
            revision: 1,
            alias: "Kind Cherry",
            deviceModel: "MacBook Pro",
            deviceType: "desktop",
            localIps: localIps,
            server: NativeUiServerSnapshot(running: true, port: 53317, https: false),
            discovery: NativeUiDiscoverySnapshot(scanning: false),
            devices: devices,
            selectedFiles: [
                NativeUiFileSnapshot(
                    id: "photo",
                    name: "IMG_4281.HEIC",
                    size: 2_400_000,
                    fileType: "image"
                ),
                NativeUiFileSnapshot(
                    id: "notes",
                    name: "Weekend Notes.md",
                    size: 42_000,
                    fileType: "text"
                ),
            ]
        )
    }
}

enum NativeSection: String, CaseIterable, Hashable, Identifiable {
    case receive = "Receive"
    case send = "Send"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .receive:
            return "tray.and.arrow.down.fill"
        case .send:
            return "paperplane.fill"
        }
    }
}
