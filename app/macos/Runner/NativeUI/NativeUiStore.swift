import Foundation

final class NativeUiStore: ObservableObject {
    @Published var selectedSection: NativeSection? = .receive
    @Published var receiveState: NativeReceiveState

    init(receiveState: NativeReceiveState = .preview) {
        self.receiveState = receiveState
    }

    func updateReceiveState(_ receiveState: NativeReceiveState) {
        self.receiveState = receiveState
    }

    func setQuickSaveMode(_ mode: NativeQuickSaveMode) {
        receiveState.quickSaveMode = mode
    }

    func acceptIncomingRequest() {
        guard case let .incoming(request) = receiveState.activity else {
            return
        }

        receiveState.activity = .receiving(
            NativeActiveReceiveTransfer(
                sender: request.sender,
                files: request.files,
                currentFileName: request.files.first?.name ?? "Incoming file",
                progress: 0.18,
                savedAutomatically: false
            )
        )
    }

    func declineIncomingRequest() {
        receiveState.activity = .idle
    }

    func cancelActiveTransfer() {
        receiveState.activity = .idle
    }

    func completeActiveTransfer() {
        guard case let .receiving(transfer) = receiveState.activity else {
            return
        }

        receiveState.activity = .completed(
            NativeCompletedReceiveTransfer(
                sender: transfer.sender,
                files: transfer.files,
                totalSize: "20.9 MB"
            )
        )
    }

    func dismissCompletedTransfer() {
        receiveState.activity = .idle
    }
}

enum NativeSection: String, CaseIterable, Hashable, Identifiable {
    case receive = "Receive"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .receive:
            return "tray.and.arrow.down.fill"
        }
    }
}
