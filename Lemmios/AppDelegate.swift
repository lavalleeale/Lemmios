import SwiftUI
import OSLog
import SimpleKeychain

class StartingTab: ObservableObject {
    @Published var requestedTab: String?
    @Published var requestedUrl: URL?
}

#if DEBUG
let baseApiUrl = "https://lemmios-dev.lavallee.one"
#else
let baseApiUrl = "https://lemmios.lavallee.one"
#endif

let startingTab = StartingTab()

extension UserDefaults {
    @objc dynamic var deviceToken: String? {
        get { string(forKey: "deviceToken") }
        set { setValue(newValue, forKey: "deviceToken") }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    private let keychain = SimpleKeychain()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        if ProcessInfo().arguments.contains("test") {
            #if targetEnvironment(simulator)
            // Disable hardware keyboards.
            let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
            UITextInputMode.activeInputModes
                // Filter `UIKeyboardInputMode`s.
                .filter { $0.responds(to: setHardwareLayout) }
                .forEach { $0.perform(setHardwareLayout, with: nil) }
            #endif
            UIView.setAnimationsEnabled(false)
        }
        if ProcessInfo().arguments.contains("delete") {
            try? FileManager.default.removeItem(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("read.db"))
            UserDefaults.standard.removePersistentDomain(forName: "com.axlav.lemmios")
            UserDefaults.standard.removePersistentDomain(forName: "group.com.axlav.lemmios")
            try! SimpleKeychain().deleteAll()
        }
        
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if let url = URL(string: response.notification.request.content.body) {
            startingTab.requestedUrl = url
        } else {
            startingTab.requestedTab = "Inbox"
        }

        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return .banner
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self

        return sceneConfiguration
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken = deviceToken.reduce("") { $0 + String(format: "%02X", $1) }
        UserDefaults.standard.deviceToken = deviceToken
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcutItem = connectionOptions.shortcutItem {
            startingTab.requestedTab = shortcutItem.type
        } else if let response = connectionOptions.notificationResponse {
            if let url = URL(string: response.notification.request.content.body) {
                startingTab.requestedUrl = url
            } else {
                startingTab.requestedTab = "Inbox"
            }
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        startingTab.requestedTab = shortcutItem.type
        completionHandler(true)
    }
}
