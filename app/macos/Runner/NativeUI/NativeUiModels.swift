import Foundation

enum NativeReceiveAvailability {
    case ready
    case offline
    case noNetwork

    var title: String {
        switch self {
        case .ready:
            return "Receiving as"
        case .offline:
            return "Offline"
        case .noNetwork:
            return "No Network"
        }
    }
}

struct NativeLocalStatus {
    let alias: String
    let platformDetail: String
    let platformSymbolName: String
    let localAddresses: [String]
    let port: Int
    let secure: Bool

    var localIds: [String] {
        localAddresses.map { address in
            let suffix = address.split(separator: ".").last.map(String.init) ?? address
            return "#\(suffix)"
        }
    }

    var primaryAddress: String {
        localAddresses.first ?? "-"
    }
}

struct NativeReceiveState {
    let availability: NativeReceiveAvailability
    let localStatus: NativeLocalStatus

    static func live(_ snapshot: NativeUiSnapshot) -> NativeReceiveState {
        let availability: NativeReceiveAvailability
        if snapshot.localIps.isEmpty {
            availability = .noNetwork
        } else if !snapshot.server.running {
            availability = .offline
        } else {
            availability = .ready
        }

        let symbolName: String
        switch snapshot.deviceType {
        case "mobile":
            symbolName = "iphone"
        case "headless":
            symbolName = "terminal"
        case "server":
            symbolName = "server.rack"
        default:
            symbolName = "macbook"
        }

        return NativeReceiveState(
            availability: availability,
            localStatus: NativeLocalStatus(
                alias: snapshot.alias,
                platformDetail: snapshot.deviceModel ?? "macOS",
                platformSymbolName: symbolName,
                localAddresses: snapshot.localIps,
                port: snapshot.server.port,
                secure: snapshot.server.https
            )
        )
    }
}
