import Combine
import Foundation

extension LemmyHttp {
    func createPost(title: String, content: String, url: String, communityId: Int, receiveValue: @escaping (PostView?, NetworkError?) -> Void) -> AnyCancellable {
        var body: SentPost {
            return SentPost(auth: self.jwt!, community_id: communityId, name: title, url: url == "" ? nil : url, body: content)
        }
        return makeRequestWithBody(path: "post", responseType: PostView.self, body: body, receiveValue: receiveValue)
    }
    
    func addComment(content: String, postId: Int, parentId: Int?, receiveValue: @escaping (CommentView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment", responseType: CommentView.self, body: SentComment(auth: jwt!, content: content, parent_id: parentId, post_id: postId), receiveValue: receiveValue)
    }
    
    func editComment(content: String, commentId: Int, receiveValue: @escaping (CommentView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment", responseType: CommentView.self, body: EditedComment(auth: jwt!, content: content, comment_id: commentId), receiveValue: receiveValue)
    }
    
    struct SentPost: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let community_id: Int
        let name: String
        let url: String?
        let body: String?
    }
    
    struct SentComment: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let content: String
        let parent_id: Int?
        let post_id: Int
    }
    
    struct EditedComment: Codable, WithMethod {
        let method = "PUT"
        let auth: String
        let content: String
        let comment_id: Int
    }
}
