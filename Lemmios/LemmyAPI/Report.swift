import Foundation

import Combine
import Foundation

extension LemmyHttp {
    func reportComment(commentId: Int, reason: String, receiveValue: @escaping (CommentReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/report", responseType: CommentReportResponse.self, body: CommentReport(auth: jwt!, comment_id: commentId, reason: reason), receiveValue: receiveValue)
    }
    
    func reportPost(postId: Int, reason: String, receiveValue: @escaping (PostReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/report", responseType: PostReportResponse.self, body: PostReport(auth: jwt!, post_id: postId, reason: reason), receiveValue: receiveValue)
    }

    struct PostReportResponse: Codable {
        let post_report_view: ApiPost
    }
    
    struct PostReport: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let post_id: Int
        let reason: String
    }

    struct CommentReportResponse: Codable {
        let comment_report_view: ApiComment
    }

    struct CommentReport: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let comment_id: Int
        let reason: String
    }
}
