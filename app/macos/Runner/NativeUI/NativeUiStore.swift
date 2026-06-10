import Foundation

final class NativeUiStore: ObservableObject {
    @Published var selectedSection: NativeSection? = .receive
    @Published var localStatus = NativeLocalStatus(
        alias: "Kind Cherry",
        shortCode: "#16 #1",
        address: "192.168.1.42",
        port: 53317,
        secure: false
    )
    @Published var quickSaveMode: NativeQuickSaveMode = .favorites
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
