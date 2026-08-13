import 'package:common/model/device.dart';
import 'package:common/model/device_info_result.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/model/state/nearby_devices_state.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

const nativeUiSnapshotSchemaVersion = 2;

final nativeUiSnapshotProvider = ViewProvider<NativeUiSnapshot>((ref) {
  final settings = ref.watch(settingsProvider);
  final network = ref.watch(localIpProvider);
  final server = ref.watch(serverProvider);
  final nearbyDevices = ref.watch(nearbyDevicesProvider);
  final deviceInfo = ref.watch(deviceInfoProvider);
  final favorites = ref.watch(favoritesProvider);
  final selectedFiles = ref.watch(selectedSendingFilesProvider);

  return NativeUiSnapshot.build(
    alias: settings.alias,
    deviceInfo: deviceInfo,
    localIps: network.localIps,
    serverRunning: server != null,
    port: server?.port ?? settings.port,
    https: server?.https ?? settings.https,
    nearbyDevices: nearbyDevices,
    favorites: favorites,
    selectedFiles: selectedFiles,
  );
}, debugLabel: 'nativeUiSnapshotProvider');

class NativeUiSnapshot {
  final String alias;
  final String? deviceModel;
  final String deviceType;
  final List<String> localIps;
  final bool serverRunning;
  final int port;
  final bool https;
  final bool scanning;
  final List<NativeUiDeviceSnapshot> devices;
  final List<NativeUiFileSnapshot> selectedFiles;

  const NativeUiSnapshot({
    required this.alias,
    required this.deviceModel,
    required this.deviceType,
    required this.localIps,
    required this.serverRunning,
    required this.port,
    required this.https,
    required this.scanning,
    required this.devices,
    required this.selectedFiles,
  });

  factory NativeUiSnapshot.build({
    required String alias,
    required DeviceInfoResult deviceInfo,
    required List<String> localIps,
    required bool serverRunning,
    required int port,
    required bool https,
    required NearbyDevicesState nearbyDevices,
    required List<FavoriteDevice> favorites,
    required List<CrossFile> selectedFiles,
  }) {
    final favoriteFingerprints = favorites
        .map((favorite) => favorite.fingerprint)
        .toSet();
    final devices =
        nearbyDevices.allDevices.values
            .map(
              (device) => NativeUiDeviceSnapshot.fromDevice(
                device,
                isFavorite: favoriteFingerprints.contains(device.fingerprint),
              ),
            )
            .toList()
          ..sort((a, b) {
            final aliasComparison = a.alias.toLowerCase().compareTo(
              b.alias.toLowerCase(),
            );
            return aliasComparison != 0
                ? aliasComparison
                : a.id.compareTo(b.id);
          });

    return NativeUiSnapshot(
      alias: alias,
      deviceModel: deviceInfo.deviceModel,
      deviceType: deviceInfo.deviceType.name,
      localIps: List.unmodifiable(localIps),
      serverRunning: serverRunning,
      port: port,
      https: https,
      scanning:
          nearbyDevices.runningFavoriteScan ||
          nearbyDevices.runningIps.isNotEmpty,
      devices: List.unmodifiable(devices),
      selectedFiles: List.unmodifiable(
        selectedFiles.indexed.map(
          (entry) =>
              NativeUiFileSnapshot.fromCrossFile(entry.$2, index: entry.$1),
        ),
      ),
    );
  }

  Map<String, Object?> toJson({required int revision}) {
    return {
      'schemaVersion': nativeUiSnapshotSchemaVersion,
      'revision': revision,
      'alias': alias,
      'deviceModel': deviceModel,
      'deviceType': deviceType,
      'localIps': localIps,
      'server': {'running': serverRunning, 'port': port, 'https': https},
      'discovery': {'scanning': scanning},
      'devices': devices
          .map((device) => device.toJson())
          .toList(growable: false),
      'selectedFiles': selectedFiles
          .map((file) => file.toJson())
          .toList(growable: false),
    };
  }
}

class NativeUiFileSnapshot {
  final String id;
  final String name;
  final int size;
  final String fileType;

  const NativeUiFileSnapshot({
    required this.id,
    required this.name,
    required this.size,
    required this.fileType,
  });

  factory NativeUiFileSnapshot.fromCrossFile(
    CrossFile file, {
    required int index,
  }) {
    final identity = file.path ?? file.name;
    return NativeUiFileSnapshot(
      id: '$identity:${file.size}:$index',
      name: file.name,
      size: file.size,
      fileType: file.fileType.name,
    );
  }

  Map<String, Object> toJson() {
    return {'id': id, 'name': name, 'size': size, 'fileType': fileType};
  }
}

class NativeUiDeviceSnapshot {
  final String id;
  final String alias;
  final String? ip;
  final int port;
  final bool https;
  final String fingerprint;
  final String? deviceModel;
  final String deviceType;
  final bool download;
  final bool isFavorite;

  const NativeUiDeviceSnapshot({
    required this.id,
    required this.alias,
    required this.ip,
    required this.port,
    required this.https,
    required this.fingerprint,
    required this.deviceModel,
    required this.deviceType,
    required this.download,
    required this.isFavorite,
  });

  factory NativeUiDeviceSnapshot.fromDevice(
    Device device, {
    required bool isFavorite,
  }) {
    final routeIdentity = device.signalingId ?? device.ip ?? 'unknown';
    return NativeUiDeviceSnapshot(
      id: '${device.fingerprint}:$routeIdentity:${device.port}',
      alias: device.alias,
      ip: device.ip,
      port: device.port,
      https: device.https,
      fingerprint: device.fingerprint,
      deviceModel: device.deviceModel,
      deviceType: device.deviceType.name,
      download: device.download,
      isFavorite: isFavorite,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'alias': alias,
      'ip': ip,
      'port': port,
      'https': https,
      'fingerprint': fingerprint,
      'deviceModel': deviceModel,
      'deviceType': deviceType,
      'download': download,
      'isFavorite': isFavorite,
    };
  }
}
