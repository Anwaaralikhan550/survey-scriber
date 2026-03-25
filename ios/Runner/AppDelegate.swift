import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var foodObjectCaptureBridge: FoodObjectCaptureBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: FoodObjectCaptureBridge.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      let bridge = FoodObjectCaptureBridge(rootViewController: controller)
      foodObjectCaptureBridge = bridge
      channel.setMethodCallHandler { [weak bridge] call, result in
        bridge?.handle(call, result: result)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
