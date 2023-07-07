import Combine
import Foundation

extension LemmyHttp {
    func voteComment(id: Int, target: Int, receiveValue: @escaping (CommentView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/like", responseType: CommentView.self, body: CommentVote(auth: jwt!, comment_id: id, score: target), receiveValue: receiveValue)
    }

    func votePost(id: Int, target: Int, receiveValue: @escaping (PostView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/like", responseType: PostView.self, body: PostVote(auth: jwt!, post_id: id, score: target), receiveValue: receiveValue)
    }
    
    struct CommentVote: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let comment_id: Int
        let score: Int
    }
    
    struct PostVote: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let post_id: Int
        let score: Int
    }
}
