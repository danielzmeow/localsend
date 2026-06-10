import Cocoa
import SwiftUI

enum NativeUiInstaller {
    static func isEnabled() -> Bool {
        if ProcessInfo.processInfo.environment["LOCALSEND_NATIVE_UI"] == "0" {
            return false
        }

        if UserDefaults.standard.object(forKey: "NativeSwiftUIShellEnabled") != nil {
            return UserDefaults.standard.bool(forKey: "NativeSwiftUIShellEnabled")
        }

        return true
    }

    static func install(in window: NSWindow) -> NSHostingController<NativeRootView>? {
        guard isEnabled() else {
            return nil
        }

        restoreSystemWindowChrome(window)

        let controller = NSHostingController(rootView: NativeRootView())
        window.contentViewController = controller

        return controller
    }

    static func restoreSystemWindowChrome(_ window: NSWindow) {
        window.title = "LocalSend"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unified
    }
}
