import SwiftUI

struct NativeSendPage: View {
    @ObservedObject var store: NativeUiStore
    let refreshDevices: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = store.refreshErrorMessage {
                RefreshErrorBanner(message: errorMessage)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            content
        }
        .navigationTitle("Send")
        .toolbar {
            ToolbarItem {
                Button(action: refreshDevices) {
                    Label("Refresh Devices", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!store.canRefreshDevices)
                .help("Refresh nearby devices")
            }
        }
        .onAppear {
            store.requestInitialDeviceRefresh(using: refreshDevices)
        }
        .onChange(of: store.snapshot?.revision) { _ in
            store.requestInitialDeviceRefresh(using: refreshDevices)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.snapshot == nil {
            NativeSendUnavailableState(
                symbolName: store.bridgeErrorMessage == nil ? "hourglass" : "exclamationmark.triangle",
                title: store.bridgeErrorMessage == nil ? "Starting LocalSend" : "Native UI Unavailable",
                message: store.bridgeErrorMessage ?? "Waiting for the Flutter runtime to publish nearby devices."
            )
        } else if store.localIps.isEmpty {
            NativeSendUnavailableState(
                symbolName: "wifi.exclamationmark",
                title: "No Network",
                message: "Connect this Mac to a local network before looking for nearby devices."
            )
        } else if store.devices.isEmpty {
            NativeSendUnavailableState(
                symbolName: store.isScanning ? "arrow.triangle.2.circlepath" : "desktopcomputer.and.arrow.down",
                title: store.isScanning ? "Looking for Devices" : "No Devices Found",
                message: store.isScanning
                    ? "Searching the local network for LocalSend devices."
                    : "Make sure LocalSend is open on the other device, then refresh."
            )
        } else {
            List(store.devices) { device in
                NativeDeviceRow(device: device)
            }
            .listStyle(.inset)
            .safeAreaInset(edge: .bottom) {
                NativeSendMilestoneNotice()
            }
        }
    }
}

private struct NativeDeviceRow: View {
    let device: NativeUiDeviceSnapshot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.symbolName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.alias)
                    .font(.headline)

                Text(device.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if device.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite device")
            }

            Label(device.https ? "HTTPS" : "HTTP", systemImage: device.https ? "lock.fill" : "lock.open")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(device.alias), \(device.detail), \(device.https ? "secure HTTPS" : "HTTP")")
    }
}

private struct NativeSendUnavailableState: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            if symbolName == "arrow.triangle.2.circlepath" {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.title2.weight(.semibold))

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct RefreshErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct NativeSendMilestoneNotice: View {
    var body: some View {
        Text("File selection and sending will be added in the next Native UI milestone.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.bar)
    }
}

#Preview("Devices") {
    NativeSendPage(store: .sendPreview, refreshDevices: {})
        .frame(width: 820, height: 600)
}
