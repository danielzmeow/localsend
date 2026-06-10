import SwiftUI

struct NativeRootView: View {
    @StateObject private var store = NativeUiStore()

    var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                NativeSidebar(selection: $store.selectedSection)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
            } detail: {
                NativeDetailView(store: store)
            }
            .frame(minWidth: 860, minHeight: 560)
        } else {
            NavigationView {
                NativeLegacySidebar(store: store)
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)
                NativeDetailView(store: store)
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .frame(minWidth: 860, minHeight: 560)
        }
    }
}

private struct NativeDetailView: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        NativeReceivePage(store: store)
    }
}
