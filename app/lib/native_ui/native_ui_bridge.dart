import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:localsend_app/native_ui/native_ui_snapshot.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

const nativeUiChannelName = 'native-ui-channel';

final _logger = Logger('NativeUiBridge');
final _nativeUiBridge = NativeUiBridge();

typedef NativeUiMethodHandler = Future<Object?> Function(String method, Object? arguments);

abstract interface class NativeUiChannel {
  void setMethodCallHandler(NativeUiMethodHandler? handler);

  Future<Object?> invokeMethod(String method, Object? arguments);
}

class FlutterNativeUiChannel implements NativeUiChannel {
  final MethodChannel _channel;

  const FlutterNativeUiChannel([
    this._channel = const MethodChannel(nativeUiChannelName),
  ]);

  @override
  void setMethodCallHandler(NativeUiMethodHandler? handler) {
    _channel.setMethodCallHandler(
      handler == null ? null : (call) => handler(call.method, call.arguments),
    );
  }

  @override
  Future<Object?> invokeMethod(String method, Object? arguments) {
    return _channel.invokeMethod<Object?>(method, arguments);
  }
}

class NativeUiBridge {
  final NativeUiChannel _channel;
  final DeepCollectionEquality _equality;

  Future<void> _publishQueue = Future.value();
  Future<void> Function()? _refreshDevices;
  Map<String, Object?>? _lastQueuedSnapshot;
  int _revision = 0;
  bool _started = false;
  bool _nativeHandlerAvailable = true;

  NativeUiBridge({
    NativeUiChannel channel = const FlutterNativeUiChannel(),
    DeepCollectionEquality equality = const DeepCollectionEquality(),
  }) : _channel = channel,
       _equality = equality;

  Future<void> start({
    required NativeUiSnapshot initialSnapshot,
    required Future<void> Function() refreshDevices,
  }) async {
    _refreshDevices = refreshDevices;
    _started = true;
    _nativeHandlerAvailable = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    await publish(initialSnapshot, force: true);
  }

  Future<void> publish(NativeUiSnapshot snapshot, {bool force = false}) {
    if (!_started || !_nativeHandlerAvailable) {
      return Future.value();
    }

    final comparableSnapshot = snapshot.toJson(revision: 0)..remove('revision');
    if (!force && _lastQueuedSnapshot != null && _equality.equals(_lastQueuedSnapshot, comparableSnapshot)) {
      return _publishQueue;
    }

    _lastQueuedSnapshot = comparableSnapshot;
    final revision = ++_revision;
    final payload = Map<String, Object?>.from(comparableSnapshot)..['revision'] = revision;

    _publishQueue = _publishQueue.then((_) async {
      try {
        await _channel.invokeMethod('snapshot', payload);
      } on MissingPluginException {
        _nativeHandlerAvailable = false;
        _logger.fine(
          'Native UI is not installed; snapshot publishing is disabled for this process.',
        );
      } catch (error, stackTrace) {
        _logger.warning(
          'Publishing Native UI snapshot failed.',
          error,
          stackTrace,
        );
      }
    });
    return _publishQueue;
  }

  Future<Object?> _handleMethodCall(String method, Object? arguments) async {
    switch (method) {
      case 'refreshDevices':
        final refreshDevices = _refreshDevices;
        if (refreshDevices == null) {
          throw PlatformException(
            code: 'native_ui_not_ready',
            message: 'Native UI bridge has not finished starting.',
          );
        }
        try {
          await refreshDevices();
          return null;
        } catch (error) {
          throw PlatformException(
            code: 'refresh_failed',
            message: error.toString(),
          );
        }
      default:
        throw MissingPluginException('Unknown Native UI method: $method');
    }
  }
}

Future<void> setupNativeUiBridge(Ref ref) async {
  await _nativeUiBridge.start(
    initialSnapshot: ref.read(nativeUiSnapshotProvider),
    refreshDevices: () async {
      ref.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());
      await ref.global.dispatchAsync(StartSmartScan(forceLegacy: true));
    },
  );
}

class NativeUiBridgeWatcher extends StatelessWidget {
  final Widget child;

  const NativeUiBridgeWatcher({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return child;
    }

    context.watch(
      nativeUiSnapshotProvider,
      listener: (_, snapshot) {
        unawaited(_nativeUiBridge.publish(snapshot));
      },
    );
    return child;
  }
}
