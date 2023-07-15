import Foundation
import SwiftUI
import Combine

class PostShareModel<Content: View>: ObservableObject {
    @Published var imageRenderer: ImageRenderer<Content>?
    var cancellable: AnyCancellable?
    
    @MainActor func updateRenderer(newBody: Content) {
        self.imageRenderer = ImageRenderer(content: newBody, scale: 3)
        self.imageRenderer?.objectWillChange.send()
        self.cancellable = imageRenderer?.objectWillChange.sink {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}
