import Combine
import Foundation
import LemmyApi

class InboxModel: ObservableObject {
    @Published var replies = [LemmyApi.CommentView]()
    @Published var messages = [LemmyApi.Message]()
    @Published var repliesStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var messagesStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var sort = LemmyApi.Sort.New
    private var cancellable: Set<AnyCancellable> = Set()
    
    func getMessages(apiModel: ApiModel, onlyUnread: Bool) {
        guard case .ready(let page) = messagesStatus else {
            return
        }
        messagesStatus = .loading(page: page)
        apiModel.lemmyHttp?.getMessages(page: page, sort: sort, unread: onlyUnread) { messages, _ in
            if let messages = messages?.private_messages.filter({ apiModel.selectedAccount! != $0.creator }) {
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
    
    func markAllRead(apiModel: ApiModel) {
        for reply in replies.enumerated().filter({ !$0.element.comment_reply!.read }) {
            apiModel.lemmyHttp?.readReply(replyId: reply.element.comment_reply!.id, read: !reply.element.comment_reply!.read) { commentView, _ in
                if commentView != nil {
                    self.replies[reply.offset].comment_reply!.read.toggle()
                }
            }.store(in: &cancellable)
        }
        for message in messages.enumerated().filter({ !$0.element.private_message.read }) {
            apiModel.lemmyHttp?.readMessage(messageId: message.element.private_message.id, read: !message.element.private_message.read) { commentView, _ in
                if commentView != nil {
                    self.messages[message.offset].private_message.read.toggle()
                }
            }.store(in: &cancellable)
        }
    }
    
    func reset() {
        cancellable.removeAll()
        replies.removeAll()
        messages.removeAll()
        repliesStatus = .ready(nextPage: 1)
        messagesStatus = .ready(nextPage: 1)
    }
}
