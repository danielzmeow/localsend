import FlutterMacOS
import SwiftUI

@MainActor
final class NativeUiSession {
    let store: NativeUiStore
    let bridge: NativeUiBridge
    let hostingController: NSHostingController<NativeRootView>

    init(binaryMessenger: FlutterBinaryMessenger) {
        let store = NativeUiStore()
        let bridge = NativeUiBridge(binaryMessenger: binaryMessenger, store: store)
        self.store = store
        self.bridge = bridge
        hostingController = NSHostingController(
            rootView: NativeRootView(
                store: store,
                actions: NativeUiActions(
                    refreshDevices: { [weak bridge] in bridge?.refreshDevices() },
                    addFiles: { [weak bridge] urls in bridge?.addFiles(urls) },
                    removeFile: { [weak bridge] id in bridge?.removeFile(id: id) },
                    clearFiles: { [weak bridge] in bridge?.clearFiles() }
                )
            )
        )
    }
}

struct NativeUiActions {
    let refreshDevices: () -> Void
    let addFiles: ([URL]) -> Void
    let removeFile: (String) -> Void
    let clearFiles: () -> Void
}

@MainActor
final class NativeUiBridge {
    private let channel: FlutterMethodChannel
    private weak var store: NativeUiStore?

    init(binaryMessenger: FlutterBinaryMessenger, store: NativeUiStore) {
        channel = FlutterMethodChannel(name: "native-ui-channel", binaryMessenger: binaryMessenger)
        self.store = store
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func refreshDevices() {
        store?.beginRefreshingDevices()

        channel.invokeMethod("refreshDevices", arguments: nil) { [weak store] result in
            let errorMessage: String?
            if let error = result as? FlutterError {
                errorMessage = error.message ?? error.code
            } else {
                errorMessage = nil
            }

            Task { @MainActor in
                store?.finishRefreshingDevices(errorMessage: errorMessage)
            }
        }
    }

    func addFiles(_ urls: [URL]) {
        let accessedUrls = urls.filter { $0.startAccessingSecurityScopedResource() }
        invokeSelectionMethod("addFiles", arguments: urls.map(\.path)) {
            accessedUrls.forEach { $0.stopAccessingSecurityScopedResource() }
        }
    }

    func removeFile(id: String) {
        invokeSelectionMethod("removeFile", arguments: id)
    }

    func clearFiles() {
        invokeSelectionMethod("clearFiles", arguments: nil)
    }

    private func invokeSelectionMethod(
        _ method: String,
        arguments: Any?,
        completion: (() -> Void)? = nil
    ) {
        store?.beginSelectionCommand()
        channel.invokeMethod(method, arguments: arguments) { [weak store] result in
            let errorMessage: String?
            if let error = result as? FlutterError {
                errorMessage = error.message ?? error.code
            } else {
                errorMessage = nil
            }

            Task { @MainActor in
                store?.finishSelectionCommand(errorMessage: errorMessage)
                completion?()
            }
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "snapshot" else {
            result(FlutterMethodNotImplemented)
            return
        }

        do {
            let snapshot = try NativeUiSnapshotDecoder.decode(arguments: call.arguments)
            Task { @MainActor [weak store] in
                store?.apply(snapshot: snapshot)
            }
            result(nil)
        } catch {
            Task { @MainActor [weak store] in
                store?.reportBridgeError(error.localizedDescription)
            }
            result(
                FlutterError(
                    code: "invalid_snapshot",
                    message: error.localizedDescription,
                    details: nil
                )
            )
        }
    }
}
