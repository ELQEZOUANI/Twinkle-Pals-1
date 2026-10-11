import Flutter
import AppTrackingTransparency
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "TwinklePalsTrackingPermission"
    ) else { return }
    let channel = FlutterMethodChannel(
      name: "twinkle_pals/tracking",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "status":
        result(Self.trackingStatusName(ATTrackingManager.trackingAuthorizationStatus))
      case "request":
        ATTrackingManager.requestTrackingAuthorization { status in
          DispatchQueue.main.async {
            result(Self.trackingStatusName(status))
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func trackingStatusName(
    _ status: ATTrackingManager.AuthorizationStatus
  ) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorized: return "authorized"
    @unknown default: return "unavailable"
    }
  }
}
