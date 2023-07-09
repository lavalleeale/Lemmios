import SimpleHaptics
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    let haptics = SimpleHapticGenerator()
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
            
        return sceneConfiguration
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        haptics.stop()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        try? haptics.start()
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    @Published var requestedTab: String? = nil
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        requestedTab = connectionOptions.shortcutItem?.type
    }
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        requestedTab = shortcutItem.type
        completionHandler(true)
    }
}
