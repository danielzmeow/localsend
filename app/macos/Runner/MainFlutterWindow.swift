import Cocoa
import FlutterMacOS
import SwiftUI
import window_manager
import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {
  private var nativeUiHostingController: NSHostingController<NativeRootView>?

  override func bitsdojo_window_configure() -> UInt {
    return BDW_HIDE_ON_STARTUP
  }
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    // window_manager: start window hidden
    hiddenWindowAtLaunch()  

    super.awakeFromNib()

    nativeUiHostingController = NativeUiInstaller.install(in: self)
  }
}
