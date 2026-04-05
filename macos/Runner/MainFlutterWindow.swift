import Cocoa
import AVFoundation
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var cameraPermissionsChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    configureCameraPermissionsChannel(for: flutterViewController)

    super.awakeFromNib()
  }

  private func configureCameraPermissionsChannel(for flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "diary_mvp/camera_permissions",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestPermission":
        guard
          let args = call.arguments as? [String: Any],
          let type = args["type"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Missing permission type",
              details: nil
            )
          )
          return
        }
        self.requestPermission(type: type, result: result)
      case "openSettings":
        guard
          let args = call.arguments as? [String: Any],
          let type = args["type"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Missing settings type",
              details: nil
            )
          )
          return
        }
        self.openPrivacySettings(type: type)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    cameraPermissionsChannel = channel
  }

  private func requestPermission(type: String, result: @escaping FlutterResult) {
    let mediaType: AVMediaType = type == "microphone" ? .audio : .video
    let status = AVCaptureDevice.authorizationStatus(for: mediaType)

    switch status {
    case .authorized:
      result(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: mediaType) { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    case .denied, .restricted:
      result(false)
    @unknown default:
      result(false)
    }
  }

  private func openPrivacySettings(type: String) {
    let anchor = type == "microphone" ? "Privacy_Microphone" : "Privacy_Camera"
    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
      return
    }
    NSWorkspace.shared.open(url)
  }
}
