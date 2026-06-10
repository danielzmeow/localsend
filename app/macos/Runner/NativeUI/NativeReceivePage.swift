import SwiftUI

struct NativeReceivePage: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                DeviceIdentityHeader(status: store.localStatus)
                NetworkIdentityGroup(status: store.localStatus)
                QuickSaveGroup(selection: $store.quickSaveMode)
            }
            .frame(width: 460)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Receive")
    }
}

private struct DeviceIdentityHeader: View {
    let status: NativeLocalStatus

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: status.platformSymbolName)
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(status.alias)
                    .font(.largeTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(status.platformName) · \(status.platformDetail)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Label("Ready to Receive", systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private struct NetworkIdentityGroup: View {
    let status: NativeLocalStatus

    var body: some View {
        GroupBox {
            VStack(spacing: 10) {
                InfoRow(
                    title: "Local IDs",
                    value: status.localIds.joined(separator: " "),
                    systemImage: "number"
                )
                InfoRow(
                    title: "Address",
                    value: status.primaryAddress,
                    systemImage: "network"
                )
                InfoRow(
                    title: "Port",
                    value: String(status.port),
                    systemImage: "point.3.connected.trianglepath.dotted"
                )
                InfoRow(
                    title: "Mode",
                    value: status.secure ? "HTTPS" : "HTTP",
                    systemImage: status.secure ? "lock" : "lock.open"
                )
            }
        } label: {
            Label("Network Identity", systemImage: "antenna.radiowaves.left.and.right")
        }
    }
}

private struct QuickSaveGroup: View {
    @Binding var selection: NativeQuickSaveMode

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Quick Save", selection: $selection) {
                    ForEach(NativeQuickSaveMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(selection.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Quick Save", systemImage: "tray.and.arrow.down")
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.body.monospacedDigit())
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}
