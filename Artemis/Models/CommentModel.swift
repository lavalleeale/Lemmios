import Foundation
import Combine

class CommentModel: VotableModel {
    @Published var likes: Int
    
    @Published var score: Int
    
    private var apiModel: ApiModel
    
    private var cancellable : Set<AnyCancellable> = Set()
    
    func vote(direction: Bool) {
        var targetVote = -1
        if ((direction && likes == 1) || (!direction && likes == -1)) {
            targetVote = 0
        } else if (direction) {
            targetVote = 1
        }
        apiModel.voteComment(id: comment.id, target: targetVote) { postView, error in
            self.score = postView?.comment_view.counts.score ?? self.score
            self.likes = targetVote
        }.store(in: &cancellable)
    }

    
    let comment: LemmyHttp.ApiComment
    let children: [LemmyHttp.ApiComment]
    
    init(comment: LemmyHttp.ApiComment, children: [LemmyHttp.ApiComment], apiModel: ApiModel) {
        self.comment = comment
        self.children = children
        self.score = comment.counts.score
        self.likes = comment.my_vote ?? 0
        self.apiModel = apiModel
    }
}

func isCommentParent(parentId: String, possibleChild: LemmyHttp.ApiComment) -> Bool {
    let childParentId = possibleChild.comment.path.components(separatedBy: ".").dropLast().last
    return parentId == childParentId
}
