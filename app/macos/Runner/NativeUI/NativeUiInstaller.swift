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
        guard isEnabled(), let contentView = window.contentView else {
            return nil
        }

        restoreSystemWindowChrome(window)

        let controller = NSHostingController(rootView: NativeRootView())
        let hostedView = controller.view
        hostedView.wantsLayer = true
        hostedView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.autoresizingMask = [.width, .height]
        contentView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        return controller
    }

    static func restoreSystemWindowChrome(_ window: NSWindow) {
        window.title = "LocalSend"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.styleMask.remove(.fullSizeContentView)
        window.isMovableByWindowBackground = false
        window.toolbarStyle = .automatic
    }
}
