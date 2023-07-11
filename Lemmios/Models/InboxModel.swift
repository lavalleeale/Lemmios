import Combine
import Foundation

class InboxModel: ObservableObject {
    @Published var replies = [LemmyHttp.ApiComment]()
    @Published var messages = [LemmyHttp.Message]()
    @Published var repliesStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var messagesStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var sort = LemmyHttp.Sort.New
    private var cancellable: Set<AnyCancellable> = Set()
    
    func getMessages(apiModel: ApiModel, onlyUnread: Bool) {
        guard case .ready(let page) = messagesStatus else {
            return
        }
        messagesStatus = .loading(page: page)
        apiModel.lemmyHttp?.getMessages(page: page, sort: sort, unread: onlyUnread) { messages, _ in
            if let messages = messages?.private_messages.filter({ $0.creator.name != apiModel.selectedAccount || $0.creator.actor_id.host() != URL(string: apiModel.url)?.host()
            }) {
                if messages.isEmpty {
                    self.messagesStatus = .done
                } else {
                    self.messagesStatus = .ready(nextPage: page + 1)
                    self.messages.append(contentsOf: messages)
                }
            } else {
                self.repliesStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func getReplies(apiModel: ApiModel, onlyUnread: Bool) {
        guard case .ready(let page) = repliesStatus else {
            return
        }
        repliesStatus = .loading(page: page)
        apiModel.lemmyHttp?.getReplies(page: page, sort: sort, unread: onlyUnread) { replies, _ in
            if let replies = replies?.replies {
                if replies.isEmpty {
                    self.repliesStatus = .done
                } else {
                    self.repliesStatus = .ready(nextPage: page + 1)
                    self.replies.append(contentsOf: replies)
                }
            } else {
                self.repliesStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func reset() {
        cancellable.removeAll()
        replies.removeAll()
        messages.removeAll()
        repliesStatus = .ready(nextPage: 1)
        messagesStatus = .ready(nextPage: 1)
    }
}
