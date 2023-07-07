import Foundation
import Combine

extension LemmyHttp {
    func savePost(save: Bool, post_id: Int, receiveValue: @escaping (LemmyHttp.PostView?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/save", query: [], responseType: PostView.self, body: PostSave(auth: jwt!, post_id: post_id, save: save), receiveValue: receiveValue)
    }
    
    struct PostSave: Codable, WithMethod {
        let method = "PUT"
        let auth: String
        let post_id: Int
        let save: Bool
    }
}
