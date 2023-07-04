import SwiftUI

@main
struct ArtemisApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(delegate.haptics)
        }
    }
}
