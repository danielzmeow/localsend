import XCTest
@testable import LocalSend

final class NativeUiSnapshotTests: XCTestCase {
    func testDecoderAcceptsVersionOneSnapshot() throws {
        let snapshot = try NativeUiSnapshotDecoder.decode(arguments: snapshotArguments(revision: 3))

        XCTAssertEqual(snapshot.revision, 3)
        XCTAssertEqual(snapshot.alias, "My Mac")
        XCTAssertEqual(snapshot.devices.first?.alias, "Phone")
        XCTAssertEqual(snapshot.devices.first?.symbolName, "iphone")
    }

    func testDecoderRejectsUnsupportedSchema() {
        XCTAssertThrowsError(
            try NativeUiSnapshotDecoder.decode(arguments: snapshotArguments(schemaVersion: 2))
        ) { error in
            guard case NativeUiSnapshotDecodingError.unsupportedSchemaVersion(2) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    @MainActor
    func testStoreRejectsStaleRevisionsAndMapsLiveState() throws {
        let store = NativeUiStore()
        let newest = try NativeUiSnapshotDecoder.decode(arguments: snapshotArguments(revision: 4))
        let stale = try NativeUiSnapshotDecoder.decode(
            arguments: snapshotArguments(revision: 2, alias: "Stale Mac")
        )

        store.apply(snapshot: newest)
        store.apply(snapshot: stale)

        XCTAssertEqual(store.snapshot?.revision, 4)
        XCTAssertEqual(store.receiveState?.localStatus.alias, "My Mac")
        XCTAssertEqual(store.devices.count, 1)
        XCTAssertTrue(store.canRefreshDevices)
    }

    @MainActor
    func testInitialRefreshWaitsForSnapshotAndRunsOnce() throws {
        let store = NativeUiStore()
        var refreshCount = 0

        store.requestInitialDeviceRefresh { refreshCount += 1 }
        store.apply(snapshot: try NativeUiSnapshotDecoder.decode(arguments: snapshotArguments(devices: [])))
        store.requestInitialDeviceRefresh { refreshCount += 1 }
        store.requestInitialDeviceRefresh { refreshCount += 1 }

        XCTAssertEqual(refreshCount, 1)
    }

    private func snapshotArguments(
        schemaVersion: Int = 1,
        revision: Int = 1,
        alias: String = "My Mac",
        devices: [[String: Any]]? = nil
    ) -> [String: Any] {
        [
            "schemaVersion": schemaVersion,
            "revision": revision,
            "alias": alias,
            "deviceModel": "MacBook Pro",
            "deviceType": "desktop",
            "localIps": ["192.168.1.10"],
            "server": ["running": true, "port": 53317, "https": false],
            "discovery": ["scanning": false],
            "devices": devices ?? [[
                "id": "phone-id",
                "alias": "Phone",
                "ip": "192.168.1.11",
                "port": 53317,
                "https": false,
                "fingerprint": "phone-fingerprint",
                "deviceModel": "iPhone",
                "deviceType": "mobile",
                "download": false,
                "isFavorite": true,
            ]],
        ]
    }
}
