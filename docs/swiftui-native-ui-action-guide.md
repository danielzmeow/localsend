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
- `app/lib/native_ui/native_ui_commands.dart`

## Snapshot Contract

The SwiftUI side should receive plain JSON-compatible snapshots. Avoid passing
Dart objects, binary file contents, streams, or generated mapper objects.

Minimum first snapshot:

```text
{
  "alias": String,
  "localIps": [String],
  "server": {
    "running": Bool,
    "port": Int,
    "https": Bool
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
      "download": Bool
    }
  ],
  "selectedFiles": [
    {
      "name": String,
      "size": Int,
      "fileType": String
    }
  ],
  "sendSessions": [...],
  "receiveSession": Object?
}
```

## Command Contract

Initial Swift-to-Dart commands:

- `nativeUiReady`
- `refreshDevices`
- `pickFiles`
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

## Near-Term Next Step

Milestone 1 is now underway on macOS:

1. Added static SwiftUI files under `app/macos/Runner/NativeUI`.
2. Attached an `NSHostingController` to the main macOS window.
3. Kept the Flutter runtime initialized behind the SwiftUI shell.
4. Added a runtime fallback: set `LOCALSEND_NATIVE_UI=0` to skip the SwiftUI
   shell and show the existing Flutter UI.

The next Milestone 1 task is verification: build the macOS Runner target and
visually inspect the static shell.
