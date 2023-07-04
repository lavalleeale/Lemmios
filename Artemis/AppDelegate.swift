import SimpleHaptics
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    let haptics = SimpleHapticGenerator()
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    return true
  }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        haptics.stop()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        try? haptics.start()
    }
}
