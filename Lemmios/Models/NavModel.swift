import Foundation
import SwiftUI

class NavModel: ObservableObject {
    @Published var path: NavigationPath

    init(startNavigated: Bool) {
        print(startNavigated)
        self.path = NavigationPath()
        if startNavigated, let data = UserDefaults.standard.data(forKey: "settings"), let decoded = try? JSONDecoder().decode(SettingsModel.SavedSettings.self, from: data) {
            DispatchQueue.main.async {
                self.path.append(PostsModel(path: decoded.defaultStart.rawValue.replacing("c/", with: "")))
            }
        }
    }
}
