import SwiftUI

struct NativeReceivePage: View {
    @ObservedObject var store: NativeUiStore

    var body: some View {
        Group {
            if let receiveState = store.receiveState {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        DeviceIdentityHeader(state: receiveState)
                        NativeReceiveMilestoneNotice()
                        NetworkIdentityGroup(status: receiveState.localStatus)
                    }
                    .frame(maxWidth: 600)
                    .padding(24)
                }
            } else {
                NativeReceiveBridgeState(message: store.bridgeErrorMessage)
            }
        }
        .navigationTitle("Receive")
    }
}

private struct NativeReceiveBridgeState: View {
    let message: String?

    var body: some View {
        VStack(spacing: 12) {
            if message == nil {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
            }

            Text(message == nil ? "Starting LocalSend" : "Native UI Unavailable")
                .font(.title2.weight(.semibold))

            Text(message ?? "Waiting for the Flutter runtime to publish local receive status.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct NativeReceiveMilestoneNotice: View {
    var body: some View {
        Label(
            "Native receive controls will be connected in a later milestone. The LocalSend runtime remains active.",
            systemImage: "info.circle"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct DeviceIdentityHeader: View {
    let state: NativeReceiveState

    private var status: NativeLocalStatus {
        state.localStatus
    }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.10))
                    .frame(width: 72, height: 72)

                Image(systemName: status.platformSymbolName)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(state.availability.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    AvailabilityIndicator(availability: state.availability)
                }

                Text(status.alias)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(status.platformDetail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(state.availability.title) \(status.alias), \(status.platformDetail)")

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

private struct AvailabilityIndicator: View {
    let availability: NativeReceiveAvailability

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 13, height: 13)
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
        .accessibilityHidden(true)
    }

    private var color: Color {
        switch availability {
        case .ready:
            return .green
        case .offline:
            return .secondary
        case .noNetwork:
            return .orange
        }
    }
}

private struct NetworkIdentityGroup: View {
    let status: NativeLocalStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Network Identity", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
                .foregroundColor(.secondary)

            let columns = Array(repeating: GridItem(.flexible()), count: 4)
            LazyVGrid(columns: columns, spacing: 12) {
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
                .fill(Color(nsColor: .controlBackgroundColor))
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
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
            }

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
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview("Ready") {
    NativeReceivePage(store: .receivePreview)
        .frame(width: 820, height: 600)
}

#Preview("No Network") {
    NativeReceivePage(store: .noNetworkPreview)
        .frame(width: 820, height: 600)
}
