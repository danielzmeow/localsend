import SwiftUI

struct NativeReceivePage: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 96))

            Text(store.localStatus.alias)
                .font(.largeTitle)

            Text(store.localStatus.shortCode)
                .font(.title)

            Picker("Quick Save", selection: $store.quickSaveMode) {
                ForEach(NativeQuickSaveMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Spacer()
        }
        .navigationTitle("Receive")
        .toolbar {
            ToolbarItemGroup {
                Button {
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

                Button {
                } label: {
                    Label("Receive Info", systemImage: "info.circle")
                }
            }
        }
    }
}
