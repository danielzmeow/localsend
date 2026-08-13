import 'package:flutter/services.dart';
import 'package:localsend_app/native_ui/native_ui_bridge.dart';
import 'package:localsend_app/native_ui/native_ui_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test(
    'publishes revisions, deduplicates snapshots, and handles refresh',
    () async {
      final channel = _FakeNativeUiChannel();
      var refreshCount = 0;
      final bridge = NativeUiBridge(channel: channel);

      await bridge.start(
        initialSnapshot: _snapshot(alias: 'First'),
        refreshDevices: () async => refreshCount++,
      );
      await bridge.publish(_snapshot(alias: 'First'));
      await bridge.publish(_snapshot(alias: 'Second'));

      expect(channel.calls, hasLength(2));
      expect(channel.calls[0].arguments, containsPair('revision', 1));
      expect(channel.calls[1].arguments, containsPair('revision', 2));
      expect(channel.calls[1].arguments, containsPair('alias', 'Second'));

      await channel.callDart('refreshDevices');
      expect(refreshCount, 1);
    },
  );

  test('rejects unknown native commands', () async {
    final channel = _FakeNativeUiChannel();
    final bridge = NativeUiBridge(channel: channel);
    await bridge.start(
      initialSnapshot: _snapshot(alias: 'Test'),
      refreshDevices: () async {},
    );

    expect(
      () => channel.callDart('unknown'),
      throwsA(isA<MissingPluginException>()),
    );
  });

  test('handles native file selection commands', () async {
    final channel = _FakeNativeUiChannel();
    final addedPaths = <String>[];
    String? removedId;
    var clearCount = 0;
    final bridge = NativeUiBridge(channel: channel);
    await bridge.start(
      initialSnapshot: _snapshot(alias: 'Test'),
      refreshDevices: () async {},
      addFiles: (paths) async => addedPaths.addAll(paths),
      removeFile: (id) async => removedId = id,
      clearFiles: () async => clearCount++,
    );

    await channel.callDart('addFiles', ['/tmp/one.txt', '/tmp/two.jpg']);
    await channel.callDart('removeFile', 'file-id');
    await channel.callDart('clearFiles');

    expect(addedPaths, ['/tmp/one.txt', '/tmp/two.jpg']);
    expect(removedId, 'file-id');
    expect(clearCount, 1);
  });
}

NativeUiSnapshot _snapshot({required String alias}) {
  return NativeUiSnapshot(
    alias: alias,
    deviceModel: 'Mac',
    deviceType: 'desktop',
    localIps: const ['127.0.0.1'],
    serverRunning: true,
    port: 53317,
    https: false,
    scanning: false,
    devices: const [],
    selectedFiles: const [],
  );
}

class _Invocation {
  final String method;
  final Map<String, Object?> arguments;

  const _Invocation(this.method, this.arguments);
}

class _FakeNativeUiChannel implements NativeUiChannel {
  NativeUiMethodHandler? handler;
  final List<_Invocation> calls = [];

  @override
  Future<Object?> invokeMethod(String method, Object? arguments) async {
    calls.add(_Invocation(method, arguments! as Map<String, Object?>));
    return null;
  }

  @override
  void setMethodCallHandler(NativeUiMethodHandler? handler) {
    this.handler = handler;
  }

  Future<Object?> callDart(String method, [Object? arguments]) {
    return handler!(method, arguments);
  }
}
