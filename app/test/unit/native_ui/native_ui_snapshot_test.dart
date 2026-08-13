import 'package:common/model/device.dart';
import 'package:common/model/device_info_result.dart';
import 'package:common/model/file_type.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/model/state/nearby_devices_state.dart';
import 'package:localsend_app/native_ui/native_ui_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test('builds a stable, sorted snapshot for the native UI', () {
    final snapshot = NativeUiSnapshot.build(
      alias: 'My Mac',
      deviceInfo: DeviceInfoResult(
        deviceType: DeviceType.desktop,
        deviceModel: 'MacBookPro',
        androidSdkInt: null,
      ),
      localIps: const ['192.168.1.10'],
      serverRunning: true,
      port: 53317,
      https: false,
      nearbyDevices: NearbyDevicesState(
        runningFavoriteScan: false,
        runningIps: const {'192.168.1.10'},
        devices: {
          '192.168.1.12': _device(alias: 'Zeta', fingerprint: 'zeta'),
          '192.168.1.11': _device(alias: 'alpha', fingerprint: 'alpha'),
        },
        signalingDevices: const {},
      ),
      favorites: const [
        FavoriteDevice(
          id: 'favorite-alpha',
          fingerprint: 'alpha',
          ip: '192.168.1.11',
          port: 53317,
          alias: 'alpha',
        ),
      ],
      selectedFiles: const [
        CrossFile(
          name: 'photo.jpg',
          fileType: FileType.image,
          size: 2048,
          thumbnail: null,
          asset: null,
          path: '/tmp/photo.jpg',
          bytes: null,
          lastModified: null,
          lastAccessed: null,
        ),
      ],
    );

    expect(snapshot.scanning, isTrue);
    expect(snapshot.devices.map((device) => device.alias), ['alpha', 'Zeta']);

    final json = snapshot.toJson(revision: 7);
    expect(json['schemaVersion'], 2);
    expect(json['revision'], 7);
    expect(json['server'], {'running': true, 'port': 53317, 'https': false});
    expect((json['devices']! as List).first, containsPair('isFavorite', true));
    expect((json['selectedFiles']! as List).single, {
      'id': '/tmp/photo.jpg:2048:0',
      'name': 'photo.jpg',
      'size': 2048,
      'fileType': 'image',
    });
  });
}

Device _device({required String alias, required String fingerprint}) {
  return Device(
    signalingId: null,
    ip: '192.168.1.${fingerprint == 'alpha' ? 11 : 12}',
    version: '2.1',
    port: 53317,
    https: false,
    fingerprint: fingerprint,
    alias: alias,
    deviceModel: 'Test Device',
    deviceType: DeviceType.desktop,
    download: false,
    discoveryMethods: {const MulticastDiscovery()},
  );
}
