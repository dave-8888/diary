import Cocoa
import AVFoundation
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let applicationIconCornerRadiusRatio: CGFloat = 0.225
  private var cameraPermissionsChannel: FlutterMethodChannel?
  private var windowIdentityChannel: FlutterMethodChannel?
  private var defaultApplicationIcon: NSImage?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    configureCameraPermissionsChannel(for: flutterViewController)
    configureWindowIdentityChannel(for: flutterViewController)
    defaultApplicationIcon = NSApp.applicationIconImage

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

  private func configureWindowIdentityChannel(for flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "diary_mvp/window_identity",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "applyWindowIdentity" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "Missing window identity payload",
            details: nil
          )
        )
        return
      }

      if let title = args["title"] as? String,
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        self.title = title
      }

      if args.keys.contains("iconPath") {
        self.applyApplicationIcon(iconPath: args["iconPath"] as? String)
      }

      result(nil)
    }

    windowIdentityChannel = channel
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

  private func applyApplicationIcon(iconPath: String?) {
    let trimmedPath = iconPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !trimmedPath.isEmpty else {
      NSApp.applicationIconImage = defaultApplicationIcon
      return
    }

    guard let icon = NSImage(contentsOfFile: trimmedPath) else {
      NSApp.applicationIconImage = defaultApplicationIcon
      return
    }

    NSApp.applicationIconImage = roundedApplicationIcon(from: icon)
  }

  private func roundedApplicationIcon(from image: NSImage) -> NSImage {
    let baseWidth = max(image.size.width, 1)
    let baseHeight = max(image.size.height, 1)
    let targetSize = NSSize(width: baseWidth, height: baseHeight)
    let targetRect = NSRect(origin: .zero, size: targetSize)
    let radius = min(targetSize.width, targetSize.height) * applicationIconCornerRadiusRatio
    let roundedImage = NSImage(size: targetSize)

    roundedImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    targetRect.fill()
    let clipPath = NSBezierPath(
      roundedRect: targetRect,
      xRadius: radius,
      yRadius: radius
    )
    clipPath.addClip()
    image.draw(
      in: targetRect,
      from: NSRect(origin: .zero, size: image.size),
      operation: .sourceOver,
      fraction: 1
    )
    roundedImage.unlockFocus()

    return roundedImage
  }
}
