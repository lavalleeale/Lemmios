import Foundation
import Combine
import SwiftUI

class PostModel: VotableModel {
    @Published var likes: Int
    
    @Published var score: Int
    
    func vote(direction: Bool) {
        var targetVote = -1
        if ((direction && likes == 1) || (!direction && likes == -1)) {
            targetVote = 0
        } else if (direction) {
            targetVote = 1
        }
        apiModel.votePost(id: post.id, target: targetVote) { postView, error in
            withAnimation(.linear(duration: 0.2)) {
                self.score = postView?.post_view.counts.score ?? self.score
                self.likes = targetVote
            }
        }.store(in: &cancellable)
    }
    
    private var apiModel: ApiModel
    private var cancellable : Set<AnyCancellable> = Set()
    public let post: LemmyHttp.ApiPost
    @Published var pageStatus = PageStatus.ready(nextPage: 1)
    @Published var sort = LemmyHttp.Sort.Hot
    @Published var comments = [LemmyHttp.ApiComment]()
    
    init(post: LemmyHttp.ApiPost, apiModel: ApiModel) {
        self.post = post
        self.apiModel = apiModel
        self.score = post.counts.score
        self.likes = post.my_vote ?? 0
    }
    
    func fetchComments() {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.getComments(postId: post.id, page: page, sort: sort) { comments, error in
            if (error == nil) {
                self.comments.append(contentsOf: comments!.comments)
                self.pageStatus = .ready(nextPage: page+1)
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func changeSort(sort: LemmyHttp.Sort) {
        self.sort = sort
        cancellable.removeAll()
        pageStatus = PageStatus.ready(nextPage: 1)
        comments.removeAll()
        fetchComments()
    }
    
    func refresh() {
        cancellable.removeAll()
        pageStatus = PageStatus.ready(nextPage: 1)
        comments.removeAll()
        fetchComments()
    }
}
