import SwiftUI
import OSLog
import SimpleKeychain

class StartingTab: ObservableObject {
    @Published var requestedTab: String?
}

#if DEBUG
let baseApiUrl = "http://laptop.lan:8080"
#else
let baseApiUrl = "https://lemmios.lavallee.one"
#endif

let startingTab = StartingTab()

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
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
            try? FileManager.default.removeItem(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("read.db"))
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            try! SimpleKeychain().deleteAll()
        }

        if launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            startingTab.requestedTab = "Inbox"
        }
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        startingTab.requestedTab = "Inbox"

        completionHandler()
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self

        return sceneConfiguration
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let jwt = UserDefaults.standard.string(forKey: "targetJwt"), let url = UserDefaults.standard.string(forKey: "serverUrl") {
            UserDefaults.standard.removeObject(forKey: "targetJwt")
            let registerUrl = URL(string: baseApiUrl + "/user/register")!

            var request = URLRequest(url: registerUrl)
            request.httpMethod = "POST"
            request.httpBody = try! JSONEncoder().encode(["jwt": jwt, "instance": url, "deviceToken": deviceToken.reduce("") { $0 + String(format: "%02X", $1) }])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data else { return }
                os_log("\(String(data: data, encoding: .utf8)!)")
            }

            task.resume()
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        startingTab.requestedTab = connectionOptions.shortcutItem?.type
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        startingTab.requestedTab = shortcutItem.type
        completionHandler(true)
    }
}
