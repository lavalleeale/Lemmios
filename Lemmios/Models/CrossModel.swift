import Foundation
import Combine
import LemmyApi

class CrossModel: ObservableObject, PostDataReceiver {
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var target = -1
    @Published var created: LemmyApi.PostView?
    func receivePostData(title: String, content: String, url: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.createPost(title: title, content: content, url: url, communityId: target) { postView, error in
            if let postView = postView?.post_view {
                self.created = postView
            }
        }.store(in: &cancellable)     
    }
}
