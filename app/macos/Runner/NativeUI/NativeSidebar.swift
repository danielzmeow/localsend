import SwiftUI

@available(macOS 13.0, *)
struct NativeSidebar: View {
    @Binding var selection: NativeSection?

    var body: some View {
        List(selection: $selection) {
            ForEach(NativeSection.allCases) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.symbolName)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("LocalSend")
    }
}

struct NativeLegacySidebar: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        List {
            ForEach(NativeSection.allCases) { section in
                NavigationLink(destination: NativeReceivePage(store: store)) {
                    Label(section.rawValue, systemImage: section.symbolName)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    store.selectedSection = section
                })
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("LocalSend")
    }
}
