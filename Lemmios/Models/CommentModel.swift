import Combine
import Foundation
import LemmyApi

class CommentModel: VotableModel {
    @Published var likes: Int
    @Published var score: Int
    @Published var upvotes: Int
    @Published var downvotes: Int
    @Published var pageStatus = CommentsPageStatus.ready
    
    private var cancellable: Set<AnyCancellable> = Set()

    @Published var comment: LemmyApi.CommentView
    @Published var children: [LemmyApi.CommentView]
    @Published var creator_banned_from_community = false
    @Published var nuked = false
    
    init(comment: LemmyApi.CommentView, children: [LemmyApi.CommentView]) {
        self.comment = comment
        self.children = children
        self.score = comment.counts.score
        self.upvotes = comment.counts.upvotes
        self.downvotes = comment.counts.downvotes
        self.likes = comment.my_vote ?? 0
        self.creator_banned_from_community = comment.creator_banned_from_community ?? false
    }
    
    func vote(direction: Bool, apiModel: ApiModel) {
        guard apiModel.selectedAccount != nil else {
            apiModel.getAuth()
            return
        }
        var targetVote = -1
        if (direction && likes == 1) || (!direction && likes == -1) {
            targetVote = 0
        } else if direction {
            targetVote = 1
        }
        apiModel.lemmyHttp?.voteComment(id: comment.id, target: targetVote) { commentView, _ in
            self.score = commentView?.comment_view.counts.score ?? self.score
            self.upvotes = commentView?.comment_view.counts.upvotes ?? self.upvotes
            self.downvotes = commentView?.comment_view.counts.downvotes ?? self.downvotes
            self.likes = targetVote
        }.store(in: &cancellable)
    }
    
    func comment(body: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.addComment(content: body, postId: comment.post.id, parentId: comment.id) { response, _ in
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
        apiModel.lemmyHttp?.getComments(postId: comment.post.id, parentId: comment.id, sort: postModel.sort) { comments, error in
            if error == nil {
                self.children.append(contentsOf: comments!.comments)
                self.pageStatus = .done
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func read(replyInfo: LemmyApi.CommentReply, apiModel: ApiModel, completion: @escaping () -> Void) {
        apiModel.lemmyHttp?.readReply(replyId: replyInfo.id, read: !replyInfo.read) { commentView, _ in
            if commentView != nil {
                completion()
            }
        }.store(in: &cancellable)
    }
    
    func edit(body: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.editComment(content: body, commentId: comment.id) { response, _ in
            if let response = response {
                self.comment = response.comment_view
            }
        }.store(in: &cancellable)
    }
    
    func delete(apiModel: ApiModel) {
        apiModel.lemmyHttp?.deleteComment(id: comment.id, deleted: !comment.comment.deleted) { response, _ in
            DispatchQueue.main.async {
                if let response = response {
                    self.comment = response.comment_view
                }
            }
        }.store(in: &cancellable)
    }
    
    func remove(apiModel: ApiModel) {
        apiModel.lemmyHttp?.removeComment(id: comment.id, removed: !comment.comment.removed) { response, _ in
            DispatchQueue.main.async {
                if let response = response {
                    self.comment = response.comment_view
                }
            }
        }.store(in: &cancellable)
    }
    
    func report(reason: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.reportComment(commentId: comment.id, reason: reason) { _, _ in }.store(in: &cancellable)
    }
    
    func distinguish(apiModel: ApiModel) {
        apiModel.lemmyHttp?.distinguish(commentId: comment.id, distinguished: !comment.comment.distinguished) { comment, _ in
            if let comment = comment {
                self.comment = comment.comment_view
            }
        }.store(in: &cancellable)
    }
    
    func ban(reason: String, remove: Bool, expires: Int?, apiModel: ApiModel) {
        apiModel.lemmyHttp!.banUser(userId: comment.creator.id, communityId: comment.community.id, ban: !creator_banned_from_community, reason: reason, remove: remove, expires: expires) { _, _ in }.store(in: &cancellable)
        creator_banned_from_community.toggle()
    }
    
    func nuke(apiModel: ApiModel) {
        for child in children.enumerated() {
            apiModel.lemmyHttp?.removeComment(id: child.element.id, removed: true) { _, _ in }.store(in: &cancellable)
        }
        remove(apiModel: apiModel)
        nuked = true
    }
    
    func updateReport(reportInfo: ReportView, apiModel: ApiModel) {
        apiModel.lemmyHttp?.updateCommentReport(reportId: Int(reportInfo.id.components(separatedBy: "_").last ?? "0") ?? 0, resolved: !reportInfo.resolved) {_, _ in}
            .store(in: &cancellable)
    }
}

func isCommentParent(parentId: Int, possibleChild: LemmyApi.CommentView) -> Bool {
    let childParentId = possibleChild.comment.path.components(separatedBy: ".").dropLast().last
    return String(parentId) == childParentId
}

enum CommentsPageStatus {
    case ready, loading, failed, done
}
