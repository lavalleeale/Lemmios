import Foundation
import SwiftUI

class NavModel: ObservableObject {
    @Published var path: NavigationPath
    let startNavigated: Bool

    init(startNavigated: Bool) {
        self.startNavigated = startNavigated
        self.path = NavigationPath()
        if startNavigated {
            DispatchQueue.main.async {
                self.path.append(PostsModel(path: UserDefaults.standard.string(forKey: "defaultStart")?.replacing("c/", with: "") ?? "All"))
            }
        }
    }

    func clear() {
        self.path.removeLast(self.startNavigated ? self.path.count - 1 : self.path.count)
    }
}
