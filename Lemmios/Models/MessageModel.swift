import Combine
import Foundation
import LemmyApi

class MessageModel: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    func read(message: LemmyApi.MessageContent, apiModel: ApiModel, completion: @escaping () -> Void) {
        apiModel.lemmyHttp?.readMessage(messageId: message.id, read: !message.read) { commentView, _ in
            if commentView != nil {
                completion()
            }
        }.store(in: &cancellable)
    }

    func send(to: Int, content: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.sendMessage(to: to, content: content) { _, _ in }.store(in: &cancellable)
    }
}
