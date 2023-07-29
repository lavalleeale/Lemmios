import Combine
import Foundation
import LemmyApi

class ResolveModel<T: Codable>: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: ResolveModel, rhs: ResolveModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var thing: URL
    
    @Published var value: T?
    
    @Published var error: String?
    
    private var cancellable: AnyCancellable?
    
    func resolve(apiModel: ApiModel) {
        if value == nil {
            if thing.host() == apiModel.lemmyHttp?.apiUrl.host() {
                if T.self == LemmyApi.PostView.self {
                    cancellable = apiModel.lemmyHttp?.getPost(id: Int(thing.lastPathComponent)!) { postView, error in
                        DispatchQueue.main.async {
                            if let postView = postView {
                                self.value = postView.post_view as? T
                            } else {
                                self.error = error?.localizedDescription
                            }
                        }
                    }
                } else if T.self == LemmyApi.CommentView.self {
                    cancellable = apiModel.lemmyHttp?.getComment(id: Int(thing.lastPathComponent)!) { postView, error in
                        DispatchQueue.main.async {
                            if let postView = postView {
                                self.value = postView.comment_view as? T
                            } else {
                                self.error = error?.localizedDescription
                            }
                        }
                    }
                }
            } else {
                cancellable = apiModel.lemmyHttp!.resolveObject(ap_id: thing) { (value: [String: T]?, error: LemmyApi.NetworkError?) in
                    DispatchQueue.main.async {
                        if let value = value {
                            self.value = value.first?.value
                        } else {
                            self.error = error?.localizedDescription
                        }
                    }
                }
            }
        }
    }
    
    init(thing: URL) {
        self.thing = thing
    }
}
