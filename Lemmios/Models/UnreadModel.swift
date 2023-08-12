import Combine
import Foundation

class UnreadModel: ObservableObject {
    @Published var unreadCount = 0
    private var cancellable = Set<AnyCancellable>()
    
    func check(apiModel: ApiModel) {
        apiModel.lemmyHttp?.getUnreadCount { unreadCount, _ in
            if let unreadCount = unreadCount {
                self.unreadCount = unreadCount.replies + unreadCount.private_messages
            } else {
                self.unreadCount = 0
            }
        }.store(in: &self.cancellable)
    }
}
