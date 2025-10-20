import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "video_downloader/saveToGallery", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "saveToGallery" {
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
          result(FlutterError(code: "invalid_args", message: "Missing path", details: nil))
          return
        }

        self.saveVideoToPhotos(path: path) { (success, errorMsg) in
          if success {
            result("saved")
          } else {
            result(FlutterError(code: "save_failed", message: errorMsg ?? "Failed to save", details: nil))
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveVideoToPhotos(path: String, completion: @escaping (Bool, String?) -> Void) {
    let url = URL(fileURLWithPath: path)
    PHPhotoLibrary.requestAuthorization { status in
      if status == .authorized || status == .limited {
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { (success, error) in
          completion(success, error?.localizedDescription)
        }
      } else {
        completion(false, "Photo library permission denied")
      }
    }
  }
}
