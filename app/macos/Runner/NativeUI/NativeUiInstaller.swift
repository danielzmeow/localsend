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

        window.isMovableByWindowBackground = true

        let controller = NSHostingController(rootView: NativeRootView())
        let hostedView = controller.view
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
}
