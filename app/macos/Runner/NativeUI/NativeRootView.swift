import SwiftUI

private extension Color {
    static let nativeWindowBackground = Color(NSColor.windowBackgroundColor)
    static let nativeSidebarBackground = Color(NSColor.underPageBackgroundColor)
    static let nativePanelBackground = Color(NSColor.controlBackgroundColor)
    static let nativeActivityBackground = Color(NSColor.textBackgroundColor).opacity(0.48)
}

struct NativeRootView: View {
    @StateObject private var store = NativeUiStore()

    var body: some View {
        HStack(spacing: 0) {
            NativeSidebar(store: store)
            Divider()
            NativeMainPane(store: store)
        }
        .frame(minWidth: 860, minHeight: 560)
        .background(Color.nativeWindowBackground)
    }
}

private struct NativeSidebar: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LocalSend")
                    .font(.title2.weight(.semibold))
                Text(store.localStatus.alias)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 22)

            VStack(spacing: 4) {
                ForEach(NativeSection.allCases) { section in
                    Button {
                        store.selectedSection = section
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: section.symbolName)
                                .frame(width: 18)
                            Text(section.rawValue)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(store.selectedSection == section ? Color.accentColor.opacity(0.14) : Color.clear)
                    )
                    .foregroundColor(store.selectedSection == section ? Color.accentColor : Color.primary)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Label(store.localStatus.address, systemImage: "network")
                Label("Port \(store.localStatus.port)", systemImage: "number")
                Label(store.localStatus.secure ? "HTTPS" : "HTTP", systemImage: store.localStatus.secure ? "lock" : "lock.open")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 18)
        .frame(width: 220)
        .background(Color.nativeSidebarBackground)
    }
}

private struct NativeMainPane: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        VStack(spacing: 0) {
            NativeToolbar(store: store)
            Divider()
            HStack(alignment: .top, spacing: 0) {
                NativeWorkPane(store: store)
                Divider()
                NativeTransferPane(store: store)
            }
        }
    }
}

private struct NativeToolbar: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        HStack(spacing: 10) {
            Text(store.selectedSection.rawValue)
                .font(.title3.weight(.semibold))
            Spacer()
            Button {
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Button {
            } label: {
                Label("Add Files", systemImage: "plus")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct NativeWorkPane: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                NativeReceiveStatusView(status: store.localStatus)
                NativeDevicesView(devices: store.devices)
                NativeQueuedFilesView(files: store.queuedFiles)
            }
            .padding(22)
        }
        .frame(minWidth: 430)
    }
}

private struct NativeReceiveStatusView: View {
    let status: NativeLocalStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ready To Receive", symbolName: "dot.radiowaves.left.and.right")
            HStack(spacing: 14) {
                StatusPill(title: "Alias", value: status.alias, symbolName: "person.crop.circle")
                StatusPill(title: "Address", value: status.address, symbolName: "network")
                StatusPill(title: "Mode", value: status.secure ? "HTTPS" : "HTTP", symbolName: status.secure ? "lock" : "lock.open")
            }
        }
    }
}

private struct NativeDevicesView: View {
    let devices: [NativeDevice]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Nearby Devices", symbolName: "desktopcomputer.and.macbook")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                ForEach(devices) { device in
                    NativeDeviceCard(device: device)
                }
            }
        }
    }
}

private struct NativeQueuedFilesView: View {
    let files: [NativeQueuedFile]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Queued Files", symbolName: "doc.on.doc")
            VStack(spacing: 8) {
                ForEach(files) { file in
                    HStack(spacing: 12) {
                        Image(systemName: "doc")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Text("\(file.kind) · \(file.size)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.nativePanelBackground)
                    )
                }
            }
        }
    }
}

private struct NativeTransferPane: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Activity", symbolName: "waveform.path.ecg")
            ForEach(store.transfers) { transfer in
                NativeTransferRow(item: transfer)
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 300)
        .background(Color.nativeActivityBackground)
    }
}

private struct NativeDeviceCard: View {
    let device: NativeDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "display")
                    .font(.title3)
                    .foregroundColor(device.online ? Color.accentColor : Color.secondary)
                Spacer()
                Circle()
                    .fill(device.online ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(device.alias)
                    .font(.headline)
                    .lineLimit(1)
                Text(device.model)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            HStack {
                Text(device.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: device.secure ? "lock" : "lock.open")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.nativePanelBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct NativeTransferRow: View {
    let item: NativeTransferItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(item.status.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            ProgressView(value: item.progress)
                .progressViewStyle(.linear)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.nativePanelBackground)
        )
    }
}

private struct SectionHeader: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

private struct StatusPill: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbolName)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.callout.weight(.medium))
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.nativePanelBackground)
        )
    }
}
