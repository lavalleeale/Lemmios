import SwiftUI

@main
struct LemmiosApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: startingTab)
                .environmentObject(delegate.haptics)
        }
    }
}
