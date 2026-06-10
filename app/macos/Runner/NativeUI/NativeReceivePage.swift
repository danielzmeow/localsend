import SwiftUI

struct NativeReceivePage: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 48)

                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 20) {
                        DeviceIdentityHeader(status: store.localStatus)
                        QuickSaveGroup(selection: $store.quickSaveMode)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)

                    NetworkIdentityGroup(status: store.localStatus)
                        .frame(width: 260)
                }
                .frame(width: 720, height: 360)

                Spacer(minLength: 48)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Receive")
    }
}

// MARK: - Device Identity Header

private struct DeviceIdentityHeader: View {
    let status: NativeLocalStatus

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            // Device icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.10))
                    .frame(width: 72, height: 72)

                Image(systemName: status.platformSymbolName)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.accentColor)
            }
            .accessibilityHidden(true)

            // Name & platform
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Receiving as")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Online indicator
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.25))
                            .frame(width: 13, height: 13)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                    }
                }

                Text(status.alias)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(status.platformDetail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Receiving as \(status.alias), \(status.platformDetail)")

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Network Identity Group

private struct NetworkIdentityGroup: View {
    let status: NativeLocalStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Label("Network Identity", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
                .foregroundColor(.secondary)

            // Stacked info cards
            VStack(spacing: 12) {
                NetworkInfoCard(
                    title: "Local IDs",
                    value: status.localIds.joined(separator: "  "),
                    systemImage: "number"
                )
                NetworkInfoCard(
                    title: "Address",
                    value: status.primaryAddress,
                    systemImage: "network"
                )
                NetworkInfoCard(
                    title: "Port",
                    value: String(status.port),
                    systemImage: "point.3.connected.trianglepath.dotted"
                )
                NetworkInfoCard(
                    title: "Protocol",
                    value: status.secure ? "HTTPS" : "HTTP",
                    systemImage: status.secure ? "lock.fill" : "lock.open.fill",
                    valueColor: status.secure ? .green : .orange
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct NetworkInfoCard: View {
    let title: String
    let value: String
    let systemImage: String
    var valueColor: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon + title row
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
            }

            // Value
            Text(value)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Quick Save Group

private struct QuickSaveGroup: View {
    @Binding var selection: NativeQuickSaveMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("Quick Save", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                // Current state badge
                Text(selection.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(selection == .off ? .secondary : .accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(selection == .off
                                  ? Color.secondary.opacity(0.12)
                                  : Color.accentColor.opacity(0.12))
                    )
            }

            // Mode picker cards
            HStack(spacing: 10) {
                ForEach(NativeQuickSaveMode.allCases) { mode in
                    QuickSaveModeCard(mode: mode, isSelected: selection == mode) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = mode
                        }
                    }
                }
            }

            // Helper text
            Text(selection.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct QuickSaveModeCard: View {
    let mode: NativeQuickSaveMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.10))
                        .frame(width: 36, height: 36)

                    Image(systemName: mode.symbolName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? .white : .secondary)
                }

                Text(mode.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.08)
                          : Color(NSColor.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct NativeReceivePage_Previews: PreviewProvider {
    static var previews: some View {
        NativeReceivePage(store: NativeUiStore())
            .frame(width: 820, height: 600)
    }
}
#endif
