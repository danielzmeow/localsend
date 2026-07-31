import SwiftUI

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
