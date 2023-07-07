import Foundation
import SwiftUI

class NavModel: ObservableObject {
    @Published var path: NavigationPath

    init(startNavigated: Bool) {
        self.path = NavigationPath()
        if startNavigated {
            DispatchQueue.main.async {
                self.path.append(PostsModel(path: UserDefaults.standard.string(forKey: "defaultStart")?.replacing("c/", with: "") ?? "All"))
            }
        }
    }
}
