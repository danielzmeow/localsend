import SwiftUI
import UniformTypeIdentifiers

struct NativeSendPage: View {
    @ObservedObject var store: NativeUiStore
    let actions: NativeUiActions

    @State private var isFileImporterPresented = false
    @State private var importerErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = importerErrorMessage ?? store.selectionErrorMessage ?? store.refreshErrorMessage {
                NativeSendErrorBanner(message: errorMessage)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            content
        }
        .navigationTitle("Send")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Add Files", systemImage: "plus")
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(store.snapshot == nil || store.isSelectionCommandRunning)
                .help("Add files to the send queue")

                Button(action: actions.refreshDevices) {
                    Label("Refresh Devices", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!store.canRefreshDevices)
                .help("Refresh nearby devices")
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true,
            onCompletion: handleFileImport
        )
        .onAppear {
            store.requestInitialDeviceRefresh(using: actions.refreshDevices)
        }
        .onChange(of: store.snapshot?.revision) { _ in
            store.requestInitialDeviceRefresh(using: actions.refreshDevices)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.snapshot == nil {
            NativeSendUnavailableState(
                symbolName: store.bridgeErrorMessage == nil ? "hourglass" : "exclamationmark.triangle",
                title: store.bridgeErrorMessage == nil ? "Starting LocalSend" : "Native UI Unavailable",
                message: store.bridgeErrorMessage ?? "Waiting for the Flutter runtime to publish send state."
            )
        } else {
            List {
                selectedFilesSection
                nearbyDevicesSection
            }
            .listStyle(.inset)
        }
    }

    private var selectedFilesSection: some View {
        Section {
            if store.selectedFiles.isEmpty {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Choose files to send", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else {
                ForEach(store.selectedFiles) { file in
                    NativeSelectedFileRow(file: file) {
                        actions.removeFile(file.id)
                    }
                    .disabled(store.isSelectionCommandRunning)
                }
            }
        } header: {
            HStack {
                Text("Files")
                if !store.selectedFiles.isEmpty {
                    Text("\(store.selectedFileCount) · \(store.formattedSelectedFileSize)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear", action: actions.clearFiles)
                        .buttonStyle(.borderless)
                        .disabled(store.isSelectionCommandRunning)
                }
            }
        } footer: {
            if !store.selectedFiles.isEmpty {
                Text("Select a nearby device after native sending is connected in Milestone 4.")
            }
        }
    }

    private var nearbyDevicesSection: some View {
        Section("Nearby Devices") {
            if store.localIps.isEmpty {
                NativeDeviceStatusRow(
                    symbolName: "wifi.exclamationmark",
                    title: "No Network",
                    message: "Connect this Mac to a local network to discover devices."
                )
            } else if store.devices.isEmpty {
                NativeDeviceStatusRow(
                    symbolName: store.isScanning ? "arrow.triangle.2.circlepath" : "desktopcomputer.and.arrow.down",
                    title: store.isScanning ? "Looking for Devices" : "No Devices Found",
                    message: store.isScanning
                        ? "Searching the local network for LocalSend devices."
                        : "Make sure LocalSend is open on the other device, then refresh.",
                    showsProgress: store.isScanning
                )
            } else {
                ForEach(store.devices) { device in
                    NativeDeviceRow(device: device)
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importerErrorMessage = nil
            guard !urls.isEmpty else { return }
            actions.addFiles(urls)
        case .failure(let error):
            importerErrorMessage = error.localizedDescription
        }
    }
}

private struct NativeSelectedFileRow: View {
    let file: NativeUiFileSnapshot
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .lineLimit(1)
                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: remove) {
                Label("Remove \(file.name)", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Remove from send queue")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(file.name), \(file.formattedSize)")
        .accessibilityAction(named: "Remove") {
            remove()
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

private struct NativeDeviceStatusRow: View {
    let symbolName: String
    let title: String
    let message: String
    var showsProgress = false

    var body: some View {
        HStack(spacing: 12) {
            if showsProgress {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 28)
            } else {
                Image(systemName: symbolName)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct NativeSendUnavailableState: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            if symbolName == "hourglass" {
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

private struct NativeSendErrorBanner: View {
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

#Preview("Files and Devices") {
    NativeSendPage(
        store: .sendPreview,
        actions: NativeUiActions(
            refreshDevices: {},
            addFiles: { _ in },
            removeFile: { _ in },
            clearFiles: {}
        )
    )
    .frame(width: 820, height: 600)
}
