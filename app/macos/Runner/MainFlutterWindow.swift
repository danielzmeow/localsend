import Cocoa
import FlutterMacOS
import SwiftUI
import window_manager
import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {
  private(set) var flutterViewController: FlutterViewController!
  private var nativeUiSession: NativeUiSession?

  override func bitsdojo_window_configure() -> UInt {
    if NativeUiInstaller.isEnabled() {
      return 0
    }

    return BDW_HIDE_ON_STARTUP
  }
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    self.flutterViewController = flutterViewController
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    if !NativeUiInstaller.isEnabled() {
      // window_manager: start window hidden
      hiddenWindowAtLaunch()
    }

    super.awakeFromNib()

    nativeUiSession = NativeUiInstaller.install(
      in: self,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    if nativeUiSession != nil {
      makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
