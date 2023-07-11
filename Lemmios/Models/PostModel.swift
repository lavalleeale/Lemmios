import Combine
import Foundation
import SwiftUI
import OSLog

class PostModel: VotableModel, Hashable {
    private var id = UUID()
    
    static func == (lhs: PostModel, rhs: PostModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var likes: Int
    @Published var score: Int
    @Published var saved: Bool
    @Published var pageStatus = CommentsPageStatus.ready
    @Published var detailsStatus: CommentsPageStatus
    @Published var sort = LemmyHttp.Sort.Hot
    @Published var comments = [LemmyHttp.ApiComment]()
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var post: LemmyHttp.ApiPostData
    @Published var creator: LemmyHttp.ApiUserData?
    @Published var community: LemmyHttp.ApiCommunityData?
    @Published var counts: LemmyHttp.ApiPostCounts?
    @Published var commentId: Int?
    
    init(post: LemmyHttp.ApiPost) {
        self.detailsStatus = .done
        self.post = post.post
        self.creator = post.creator
        self.community = post.community
        self.counts = post.counts
        self.score = post.counts.score
        self.saved = post.saved ?? false
        self.likes = post.my_vote ?? 0
        if let defaultCommentSort = UserDefaults.standard.string(forKey: "defaultCommentSort") {
            self.sort = LemmyHttp.Sort(rawValue: defaultCommentSort)!
        }
    }
    
    init(post: LemmyHttp.ApiPostData, comment: LemmyHttp.ApiComment? = nil) {
        if let comment = comment {
            let commentId = Int(comment.comment.path.split(separator: ".").dropLast().last!, radix: 10)
            if commentId != 0 {
                self.commentId = commentId
                self.pageStatus = .done
            }
            self.comments = [comment]
        }
        self.detailsStatus = .ready
        self.post = post
        self.score = 0
        self.saved = false
        self.likes = 0
        if let defaultCommentSort = UserDefaults.standard.string(forKey: "defaultCommentSort") {
            self.sort = LemmyHttp.Sort(rawValue: defaultCommentSort)!
        }
    }
    
    func getPostDetails(apiModel: ApiModel) {
        guard case .ready = detailsStatus else {
            return
        }
        detailsStatus = .loading
        apiModel.lemmyHttp?.getPost(id: post.id) { post, error in
            if let post = post?.post_view {
                self.detailsStatus = .done
                self.creator = post.creator
                self.community = post.community
                self.counts = post.counts
                self.score = post.counts.score
                self.saved = post.saved ?? false
                self.likes = post.my_vote ?? 0
            } else {
                os_log("\(error)")
                self.detailsStatus = .failed
            }
        }.store(in: &cancellable)
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
        apiModel.lemmyHttp?.votePost(id: post.id, target: targetVote) { postView, _ in
            if let postView = postView?.post_view {
                self.score = postView.counts.score
                self.saved = postView.saved!
                self.likes = postView.my_vote!
            }
        }.store(in: &cancellable)
    }
    
    func fetchComments(apiModel: ApiModel) {
        guard case .ready = pageStatus else {
            return
        }
        pageStatus = .loading
        apiModel.lemmyHttp?.getComments(postId: post.id, parentId: commentId, sort: sort) { comments, error in
            if error == nil {
                if self.commentId == nil {
                    self.comments.append(contentsOf: comments!.comments)
                } else {
                    self.comments = comments!.comments
                }
                self.pageStatus = .done
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func changeSort(sort: LemmyHttp.Sort, apiModel: ApiModel) {
        self.sort = sort
        cancellable.removeAll()
        pageStatus = CommentsPageStatus.ready
        comments.removeAll()
        fetchComments(apiModel: apiModel)
    }
    
    func refresh(apiModel: ApiModel) {
        cancellable.removeAll()
        pageStatus = CommentsPageStatus.ready
        comments.removeAll()
        fetchComments(apiModel: apiModel)
    }
    
    func comment(body: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.addComment(content: body, postId: post.id, parentId: nil) { response, error in
            if error == nil {
                if case .done = self.pageStatus, self.comments.count != 0 {
                    self.comments.insert(response!.comment_view, at: 0)
                }
            }
        }.store(in: &cancellable)
    }
    
    func save(apiModel: ApiModel) {
        apiModel.lemmyHttp?.savePost(save: !saved, post_id: post.id) { postView, _ in
            if let postView = postView?.post_view {
                self.score = postView.counts.score
                self.saved = postView.saved!
                self.likes = postView.my_vote!
            }
        }.store(in: &cancellable)
    }
    
    func report(reason: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.reportPost(postId: post.id, reason: reason) { response, _ in
            if let response = response?.post_report_view {
                self.score = response.counts.score
            }
        }.store(in: &cancellable)
    }
}
