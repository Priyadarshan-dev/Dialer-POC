import Flutter
import UIKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let callDirectoryChannel = FlutterMethodChannel(name: "com.liquid.dialer/call_directory",
                                              binaryMessenger: controller.binaryMessenger)
    
    callDirectoryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "syncAndReload" {
        guard let args = call.arguments as? [String: Any],
              let appGroupId = args["appGroupId"] as? String,
              let fileName = args["fileName"] as? String,
              let data = args["data"] as? [String: String] else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
          return
        }
        
        self.saveToAppGroup(appGroupId: appGroupId, fileName: fileName, data: data) { success in
          if success {
            self.reloadExtension(identifier: "\(Bundle.main.bundleIdentifier!).CallDirectoryExtension") { reloadSuccess in
                result(reloadSuccess)
            }
          } else {
            result(FlutterError(code: "SYNC_FAILED", message: "Failed to save to App Group", details: nil))
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveToAppGroup(appGroupId: String, fileName: String, data: [String: String], completion: @escaping (Bool) -> Void) {
      guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
          print("[DEBUG] AppDelegate: Failed to get App Group container")
          completion(false)
          return
      }
      
      let fileURL = sharedContainer.appendingPathComponent(fileName)
      
      do {
          let jsonData = try JSONSerialization.data(withReservedKeys: data, options: .prettyPrinted)
          try jsonData.write(to: fileURL)
          print("[DEBUG] AppDelegate: Successfully saved notes to \(fileURL.path)")
          completion(true)
      } catch {
          print("[DEBUG] AppDelegate: Error saving to App Group: \(error)")
          completion(false)
      }
  }
  
  private func reloadExtension(identifier: String, completion: @escaping (Bool) -> Void) {
      CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: identifier) { error in
          if let error = error {
              print("[DEBUG] AppDelegate: Error reloading extension: \(error)")
              completion(false)
          } else {
              print("[DEBUG] AppDelegate: Extension reload successful")
              completion(true)
          }
      }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

extension JSONSerialization {
    static func data(withReservedKeys dictionary: [String: String], options: JSONSerialization.WritingOptions = []) throws -> Data {
        // CallKit requires numbers to be sorted and unique.
        // We sort them here to ensure the extension gets a sorted list.
        let sortedKeys = dictionary.keys.sorted()
        var sortedArray: [[String: String]] = []
        for key in sortedKeys {
            if let value = dictionary[key] {
                sortedArray.append(["number": key, "label": value])
            }
        }
        return try JSONSerialization.data(withJSONObject: sortedArray, options: options)
    }
}
