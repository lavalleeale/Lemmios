import Combine
import Foundation

class CommentModel: VotableModel {
    @Published var likes: Int
    @Published var score: Int
    @Published var pageStatus = CommentsPageStatus.ready
    
    private var cancellable: Set<AnyCancellable> = Set()

    let comment: LemmyHttp.ApiComment
    @Published var children: [LemmyHttp.ApiComment]
    
    init(comment: LemmyHttp.ApiComment, children: [LemmyHttp.ApiComment]) {
        self.comment = comment
        self.children = children
        self.score = comment.counts.score
        self.likes = comment.my_vote ?? 0
    }
    
    func vote(direction: Bool, apiModel: ApiModel) {
        guard apiModel.selectedAccount != "" else {
            apiModel.getAuth()
            return
        }
        var targetVote = -1
        if (direction && likes == 1) || (!direction && likes == -1) {
            targetVote = 0
        } else if direction {
            targetVote = 1
        }
        apiModel.lemmyHttp!.voteComment(id: comment.id, target: targetVote) { commentView, _ in
            self.score = commentView?.comment_view.counts.score ?? self.score
            self.likes = targetVote
        }.store(in: &cancellable)
    }
    
    func comment(body: String, apiModel: ApiModel) {
        apiModel.lemmyHttp!.addComment(content: body, postId: comment.post.id, parentId: comment.id) { response, _ in
            if let response = response {
                self.children.append(response.comment_view)
            }
        }.store(in: &cancellable)
    }
    
    func fetchComments(apiModel: ApiModel, postModel: PostModel) {
        guard case .ready = pageStatus else {
            return
        }
        pageStatus = .loading
        apiModel.lemmyHttp!.getComments(postId: comment.post.id, parentId: comment.id, sort: postModel.sort) { comments, error in
            if error == nil {
                self.children.append(contentsOf: comments!.comments)
                self.pageStatus = .done
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func read(replyInfo: LemmyHttp.ReplyInfo, apiModel: ApiModel, completion: @escaping ()->Void) {
        apiModel.lemmyHttp!.readReply(replyId: replyInfo.id, read: !replyInfo.read) { commentView, _ in
            if commentView != nil {
                completion()
            }
        }.store(in: &cancellable)
    }
}

func isCommentParent(parentId: Int, possibleChild: LemmyHttp.ApiComment) -> Bool {
    let childParentId = possibleChild.comment.path.components(separatedBy: ".").dropLast().last
    return String(parentId) == childParentId
}

enum CommentsPageStatus {
    case ready, loading, failed, done
}
