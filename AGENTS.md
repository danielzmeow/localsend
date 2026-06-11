# Agent Notes

## SwiftUI Native UI Direction

- This fork prioritizes personal-use macOS SwiftUI work over broad legacy macOS support.
- Target macOS 13.0+ for new NativeUI work; do not preserve macOS 11 compatibility.
- Prefer modern SwiftUI/macOS APIs when they make the code clearer or the UI more native.
- Prefer modern SwiftUI/macOS APIs available on macOS 13+ when they make the code clearer or the UI more native.
- Keep LocalSend's existing Flutter/runtime logic alive until the SwiftUI bridge has real feature parity.
- For NativeUI changes, prefer small state models and Canvas-friendly previews so the UI can be iterated in Xcode.
