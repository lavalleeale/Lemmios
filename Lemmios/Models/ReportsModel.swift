import Combine
import Foundation
import LemmyApi
import LinkPreview
import SwiftUI
import WidgetKit

class ReportsModel: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: ReportsModel, rhs: ReportsModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var posts = [LemmyApi.PostReportView]()
    @Published var comments = [LemmyApi.CommentReportView]()
    @Published var postsStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var commentsStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var showResolved = false
    let communityId: Int
    
    init(communityId: Int) {
        self.communityId = communityId
    }
    
    func fetchPosts(apiModel: ApiModel) {
        guard case let .ready(page) = postsStatus else {
            return
        }
        postsStatus = .loading(page: page)
        apiModel.lemmyHttp?.getPostReports(page: page, unresolved_only: !showResolved, community_id: communityId) { reports, _ in
            if let reports = reports {
                if reports.post_reports.isEmpty {
                    self.postsStatus = .done
                } else {
                    self.posts.append(contentsOf: reports.post_reports)
                    self.postsStatus = .ready(nextPage: page + 1)
                }
            } else {
                self.postsStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func fetchComments(apiModel: ApiModel) {
        guard case let .ready(page) = commentsStatus else {
            return
        }
        commentsStatus = .loading(page: page)
        apiModel.lemmyHttp?.getCommentReports(page: page, unresolved_only: !showResolved, community_id: communityId) { reports, _ in
            if let reports = reports {
                if reports.comment_reports.isEmpty {
                    self.commentsStatus = .done
                } else {
                    self.comments.append(contentsOf: reports.comment_reports)
                    self.commentsStatus = .ready(nextPage: page + 1)
                }
            } else {
                self.commentsStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func refresh(apiModel: ApiModel) {
        cancellable.removeAll()
        posts.removeAll()
        comments.removeAll()
        postsStatus = .ready(nextPage: 1)
        commentsStatus = .ready(nextPage: 1)
        fetchPosts(apiModel: apiModel)
        fetchComments(apiModel: apiModel)
    }
}
