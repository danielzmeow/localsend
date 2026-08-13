# SwiftUI Native UI Action Guide

This document tracks the plan for building a personal-use SwiftUI native UI for
LocalSend while preserving the existing transfer logic during the early stages.

## Goal

Build an Apple-native LocalSend experience with SwiftUI for macOS first, then
iOS, without immediately rewriting the whole LocalSend protocol stack.

The first usable target is a SwiftUI macOS shell that can:

- Show local receive status.
- Show discovered devices.
- Pick files.
- Send selected files to a selected device.
- Show basic send and receive progress.

## Recommended Architecture

Start with a hybrid architecture:

```text
SwiftUI UI
  <-> NativeUiBridge.swift
  <-> Flutter MethodChannel
  <-> Dart NativeUiBridge
  <-> Refena providers / isolates / Rust core
```

This keeps the currently working LocalSend runtime alive while replacing the
visible UI piece by piece.

Do not start by replacing the Flutter engine. Keep Flutter initialized as the
runtime coordinator until the SwiftUI flow proves itself.

## Repository Boundaries

- `app/lib`
  Flutter app, Refena state, routing, settings, transfer orchestration, and UI.

- `app/lib/config/init.dart`
  Main startup path. Initializes Rust bridge, persistence, tray/window behavior,
  child isolates, local HTTP server, multicast discovery, and signaling.

- `app/lib/provider/network/server/server_provider.dart`
  Production receive-side HTTP server and receive session state.

- `app/lib/provider/network/send_provider.dart`
  Production send workflow. Currently coupled to Flutter pages and dialogs.

- `common/lib`
  Shared Dart DTOs, device model, isolate tasks, multicast and HTTP discovery,
  and upload helpers.

- `core`
  Rust core library. It contains useful HTTP client, crypto, transfer models,
  and WebRTC code. Its HTTP server is not yet a complete replacement for the
  Dart receive server.

- `app/rust`
  Flutter Rust Bridge wrapper around `core`.

- `app/macos/Runner`
  Best first target for SwiftUI integration.

- `app/ios/Runner`
  Later target after the macOS bridge and UI model settle.

## Important Technical Findings

- macOS already has native Swift files and a SwiftUI-based share extension.
- Existing method channels:
  - iOS: `ios-delegate-channel`
  - macOS: `main-delegate-channel`
- Flutter initializes the real app runtime through `preInit` and `postInit`.
- Discovery runs through Dart providers and child isolates.
- Receive-side HTTP server logic is currently Dart-based.
- Send-side HTTP client calls already use Rust via Flutter Rust Bridge.
- `core/src/http/server` is not ready to power full file receiving by itself.
- `sendProvider.startSession` opens Flutter pages and dialogs, so it needs a
  headless/native-friendly path before SwiftUI can fully own send UX.

## Initial Implementation Strategy

Use macOS as the first platform.

1. Keep `MainFlutterWindow` and the existing Flutter runtime.
2. Add a SwiftUI view layer through `NSHostingController`.
3. Add a dedicated `native-ui-channel`.
4. Send simple JSON snapshots from Dart to Swift.
5. Send simple commands from Swift to Dart.
6. Gradually replace visible Flutter screens with SwiftUI surfaces.

The first implementation should be reversible. A feature flag or build-time
switch should allow falling back to the current Flutter UI.

## Proposed New Files

Swift:

- `app/macos/Runner/NativeUI/NativeRootView.swift`
- `app/macos/Runner/NativeUI/NativeUiStore.swift`
- `app/macos/Runner/NativeUI/NativeUiBridge.swift`
- `app/macos/Runner/NativeUI/NativeUiModels.swift`

Dart:

- `app/lib/native_ui/native_ui_bridge.dart`
- `app/lib/native_ui/native_ui_snapshot.dart`

## Snapshot Contract

The SwiftUI side should receive plain JSON-compatible snapshots. Avoid passing
Dart objects, binary file contents, streams, or generated mapper objects.

Version 2 snapshot:

```text
{
  "schemaVersion": 2,
  "revision": Int,
  "alias": String,
  "deviceModel": String?,
  "deviceType": String,
  "localIps": [String],
  "server": {
    "running": Bool,
    "port": Int,
    "https": Bool
  },
  "discovery": {
    "scanning": Bool
  },
  "devices": [
    {
      "id": String,
      "alias": String,
      "ip": String?,
      "port": Int,
      "https": Bool,
      "fingerprint": String,
      "deviceModel": String?,
      "deviceType": String,
      "download": Bool,
      "isFavorite": Bool
    }
  ],
  "selectedFiles": [
    {
      "id": String,
      "name": String,
      "size": Int,
      "fileType": String
    }
  ]
}
```

Snapshots are revisioned, published serially, and deduplicated in Dart. Swift
rejects unsupported schema versions and ignores stale revisions.

## Command Contract

Implemented Swift-to-Dart commands:

- `refreshDevices`
- `addFiles`
- `removeFile`
- `clearFiles`

Planned commands for later milestones:

- `sendToDevice`
- `acceptReceive`
- `declineReceive`
- `cancelSession`
- `setQuickSave`

Keep command arguments simple and explicit. Prefer IDs, file paths, booleans,
and strings.

## Milestones

### Milestone 1: Static SwiftUI Shell

- Add SwiftUI root view on macOS.
- Render fake receive status, fake device list, and fake file queue.
- Confirm the shell can coexist with the Flutter runtime.
- Confirm fallback to Flutter UI is still possible.

### Milestone 2: Live Status Snapshot

- Add Dart `native_ui` bridge.
- Send real alias, local IPs, server status, and nearby devices to SwiftUI.
- Trigger device refresh from SwiftUI.

### Milestone 3: File Selection

- Use `NSOpenPanel` on macOS.
- Pass selected file paths to Dart.
- Reuse `selectedSendingFilesProvider` for conversion and state.
- Show selected files in SwiftUI.

### Milestone 4: Headless Send MVP

- Extract a native-friendly send path from `sendProvider`.
- Avoid Flutter navigation from SwiftUI-initiated sends.
- Surface PIN and failure states through bridge events instead of Flutter
  dialogs.
- Show progress in SwiftUI.

### Milestone 5: Receive MVP

- Publish incoming receive requests to SwiftUI.
- Accept or decline from SwiftUI.
- Show per-file receive status.
- Preserve destination folder and quick-save behavior.

### Milestone 6: iOS Adaptation

- Reuse snapshot and command contracts.
- Add `UIHostingController` integration.
- Replace macOS file picker paths with document picker/security-scoped access.

## Risks

- Flutter routing is currently mixed into send and receive flows.
- Receive server is Dart-based, so a pure SwiftUI/Rust app is not a quick first
  step.
- Some platform plugins assume Flutter UI lifecycle.
- File access differs sharply between macOS and iOS.
- MethodChannel snapshots must avoid large payloads, especially thumbnails and
  file bytes.

## Current Progress

Milestones 1 through 3 are implemented on macOS:

1. The main window hosts the SwiftUI shell while the Flutter runtime remains
   initialized behind it.
2. `native-ui-channel` publishes live local/server/discovery/device snapshots
   from Refena providers after runtime initialization.
3. The Send page renders real nearby devices and can request a forced discovery
   refresh from Dart. It also requests one initial refresh when the live device
   list is empty and networking is available.
4. The Receive page renders live local status. Milestone 1's fake transfer and
   quick-save models and controls have been removed.
5. Set `LOCALSEND_NATIVE_UI=0` to skip the SwiftUI shell and show the existing
   Flutter UI.
6. Dart unit tests cover snapshot mapping, revision publishing, deduplication,
   and refresh commands. The macOS `RunnerTests` target covers snapshot decoding,
   schema validation, revision ordering, and live state mapping.
7. The Send page uses the native macOS file importer, keeps security-scoped
   access alive while Dart adds files to `selectedSendingFilesProvider`, and
   renders the real queue with add, remove, and clear controls.

The next implementation step is Milestone 4: extract a native-friendly send
session that does not navigate to Flutter pages or present Flutter dialogs.
