import Foundation

struct NativeUiSnapshot: Decodable, Equatable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let revision: Int
    let alias: String
    let deviceModel: String?
    let deviceType: String
    let localIps: [String]
    let server: NativeUiServerSnapshot
    let discovery: NativeUiDiscoverySnapshot
    let devices: [NativeUiDeviceSnapshot]
}

struct NativeUiServerSnapshot: Decodable, Equatable {
    let running: Bool
    let port: Int
    let https: Bool
}

struct NativeUiDiscoverySnapshot: Decodable, Equatable {
    let scanning: Bool
}

struct NativeUiDeviceSnapshot: Decodable, Equatable, Identifiable {
    let id: String
    let alias: String
    let ip: String?
    let port: Int
    let https: Bool
    let fingerprint: String
    let deviceModel: String?
    let deviceType: String
    let download: Bool
    let isFavorite: Bool

    var symbolName: String {
        switch deviceType {
        case "mobile":
            return "iphone"
        case "web":
            return "globe"
        case "headless":
            return "terminal"
        case "server":
            return "server.rack"
        default:
            return "desktopcomputer"
        }
    }

    var detail: String {
        deviceModel ?? ip ?? "LocalSend device"
    }
}

enum NativeUiSnapshotDecodingError: LocalizedError {
    case invalidArguments
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "The Flutter runtime sent an invalid Native UI snapshot."
        case .unsupportedSchemaVersion(let version):
            return "Native UI snapshot schema version \(version) is not supported."
        }
    }
}

enum NativeUiSnapshotDecoder {
    static func decode(arguments: Any?) throws -> NativeUiSnapshot {
        guard let arguments, JSONSerialization.isValidJSONObject(arguments) else {
            throw NativeUiSnapshotDecodingError.invalidArguments
        }

        let data = try JSONSerialization.data(withJSONObject: arguments)
        let snapshot = try JSONDecoder().decode(NativeUiSnapshot.self, from: data)
        guard snapshot.schemaVersion == NativeUiSnapshot.supportedSchemaVersion else {
            throw NativeUiSnapshotDecodingError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }
        return snapshot
    }
}
