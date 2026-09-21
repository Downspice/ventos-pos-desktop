import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let pickerChannel = FlutterMethodChannel(
      name: "ventos/file_picker",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    pickerChannel.setMethodCallHandler { call, result in
      guard call.method == "pickImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let presentPanel = {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image, .jpeg, .png, .gif, .webP, .bmp]
        let response = panel.runModal()
        let path: Any = (response == .OK ? panel.url?.path : nil) ?? NSNull()
        result(["response": response.rawValue, "path": path, "presentation": "runModal"])
      }
      if Thread.isMainThread {
        presentPanel()
      } else {
        DispatchQueue.main.sync(execute: presentPanel)
      }
    }

    super.awakeFromNib()
  }
}
