import Combine
import Foundation
import LemmyApi
import OSLog
import SwiftUI

class PostModel: VotableModel, Hashable, PostDataReceiver {
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
    @Published var read: Bool
    @Published var pageStatus = CommentsPageStatus.ready
    @Published var parentStatus = CommentsPageStatus.ready
    @Published var detailsStatus: CommentsPageStatus
    @Published var sort = LemmyApi.Sort.Hot
    @Published var comments = [LemmyApi.ApiComment]()
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var post: LemmyApi.ApiPostData
    @Published var creator: LemmyApi.ApiUserData?
    @Published var community: LemmyApi.ApiCommunityData?
    @Published var counts: LemmyApi.ApiPostCounts?
    @Published var selectedComment: LemmyApi.ApiComment?
    
    init(post: LemmyApi.ApiPost) {
        self.read = DBModel.instance.isRead(postId: post.post.id)
        self.detailsStatus = .done
        self.post = post.post
        self.creator = post.creator
        self.community = post.community
        self.counts = post.counts
        self.score = post.counts.score
        self.saved = post.saved ?? false
        self.likes = post.my_vote ?? 0
        if let defaultCommentSort = UserDefaults.standard.string(forKey: "defaultCommentSort") {
            self.sort = LemmyApi.Sort(rawValue: defaultCommentSort)!
        }
    }
    
    init(post: LemmyApi.ApiPostData, comment: LemmyApi.ApiComment? = nil) {
        self.read = DBModel.instance.isRead(postId: post.id)
        if let comment = comment {
            self.selectedComment = comment
            self.comments = [comment]
        }
        self.detailsStatus = .ready
        self.post = post
        self.score = 0
        self.saved = false
        self.likes = 0
        if let defaultCommentSort = UserDefaults.standard.string(forKey: "defaultCommentSort") {
            self.sort = LemmyApi.Sort(rawValue: defaultCommentSort)!
        }
    }
    
    func getParent(currentDepth: Int, apiModel: ApiModel) {
        guard case .ready = parentStatus else {
            return
        }
        parentStatus = .loading
        let split = selectedComment!.comment.path.split(separator: ".")
        apiModel.lemmyHttp?.getComment(id: Int(split.dropFirst(currentDepth - 2).first!, radix: 10)!) { comment, error in
            DispatchQueue.main.async {
                if let comment = comment {
                    self.parentStatus = .ready
                    self.comments.append(comment.comment_view)
                } else {
                    print(error)
                }
            }
        }.store(in: &cancellable)
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
        var parentId = selectedComment == nil ? nil : Int(selectedComment!.comment.path.split(separator: ".").dropLast().last!, radix: 10)
        if parentId == 0 {
            parentId = nil
        }
        apiModel.lemmyHttp?.getComments(postId: post.id, parentId: parentId, sort: sort) { comments, error in
            if error == nil {
                self.comments = comments!.comments
                self.pageStatus = .done
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func changeSort(sort: LemmyApi.Sort, apiModel: ApiModel) {
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
                if case .done = self.pageStatus {
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
    
    func delete(apiModel: ApiModel) {
        apiModel.lemmyHttp?.deletePost(id: post.id, deleted: !post.deleted) { response, _ in
            DispatchQueue.main.async {
                if let response = response {
                    self.post = response.post_view.post
                }
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
    
    func receivePostData(title: String, content: String, url: String, apiModel: ApiModel) {
        apiModel.lemmyHttp!.editPost(title: title, content: content, url: url, postId: post.id) { newValue, error in
            if let newValue = newValue {
                self.post = newValue.post_view.post
            }
        }.store(in: &cancellable)
    }
}
