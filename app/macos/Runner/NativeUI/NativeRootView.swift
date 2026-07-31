import SwiftUI

struct NativeRootView: View {
    @ObservedObject var store: NativeUiStore
    let refreshDevices: () -> Void

    var body: some View {
        NavigationSplitView {
            NativeSidebar(selection: $store.selectedSection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            switch store.selectedSection ?? .receive {
            case .receive:
                NativeReceivePage(store: store)
            case .send:
                NativeSendPage(store: store, refreshDevices: refreshDevices)
            }
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}

#Preview {
    NativeRootView(store: .sendPreview, refreshDevices: {})
        .frame(width: 900, height: 640)
}
