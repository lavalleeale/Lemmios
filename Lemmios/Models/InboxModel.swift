import Foundation
import Combine

class InboxModel: ObservableObject {
    @Published var replies = [LemmyHttp.Reply]()
    @Published var repliesStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var sort = LemmyHttp.Sort.New
    private var cancellable: Set<AnyCancellable> = Set()
    
    func getData(apiModel: ApiModel, onlyUnread: Bool) {
        guard case .ready(let page) = repliesStatus else {
            return
        }
        repliesStatus = .loading(page: page)
        apiModel.lemmyHttp!.getReplies(page: page, sort: sort, unread: onlyUnread) { replies, error in
            if let replies = replies {
                if replies.replies.isEmpty {
                    self.repliesStatus = .done
                } else {
                    self.repliesStatus = .ready(nextPage: page + 1)
                    self.replies.append(contentsOf: replies.replies)
                }
            } else {
                self.repliesStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func reset() {
        cancellable.removeAll()
        replies.removeAll()
        repliesStatus = .ready(nextPage: 1)
    }
}
