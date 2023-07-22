import Combine
import WidgetKit
import Foundation
import LemmyApi
import SwiftUI

class PostsModel: ObservableObject, Hashable, PostDataReceiver {
    private var id = UUID()
    
    static func == (lhs: PostsModel, rhs: PostsModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var posts = [LemmyApi.ApiPost]()
    @Published var sort = LemmyApi.Sort.Active
    @Published var time = LemmyApi.TopTime.All
    @Published var pageStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var skipped = 0
    @Published var communityView: LemmyApi.CommunityView?
    @Published var postCreated = false
    @Published var createdPost: LemmyApi.ApiPost?
    @Published var notFound = false
    @AppStorage("hideRead") var hideRead = false
    @AppStorage("enableRead") var enableRead = true
    @AppStorage("filters") var filters = [String]()
    var path: String
    
    init(path: String) {
        self.path = path
        if let defaultPostSort = UserDefaults.standard.string(forKey: "defaultPostSort") {
            self.sort = LemmyApi.Sort(rawValue: defaultPostSort)!
        }
        if let defaultPostSortTime = UserDefaults.standard.string(forKey: "defaultPostSortTime") {
            self.time = LemmyApi.TopTime(rawValue: defaultPostSortTime)!
        }
    }
    
    func fetchPosts(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        if posts.isEmpty && !specialPostPathList.contains(path) {
            apiModel.lemmyHttp?.getCommunity(name: path) { posts, _ in
                if let posts = posts {
                    self.communityView = posts
                }
            }.store(in: &cancellable)
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp?.getPosts(path: path, page: page, sort: sort, time: time) { posts, error in
            DispatchQueue.main.async {
                if let posts = posts {
                    if posts.posts.isEmpty {
                        self.pageStatus = .done
                    } else {
                        let posts = posts.posts.filter { post in
                            let shouldHide = (self.hideRead && self.enableRead && DBModel.instance.isRead(postId: post.id)) || self.filters.map { post.post.name.contains($0) }.contains(true)
                            if shouldHide {
                                self.skipped += 1
                            }
                            return !shouldHide
                        }
                        self.posts.append(contentsOf: posts)
                        self.pageStatus = .ready(nextPage: page + 1)
                        if posts.isEmpty {
                            self.fetchPosts(apiModel: apiModel)
                        }
                    }
                } else {
                    if case let .network(code, _) = error! {
                        if code == 404 {
                            self.notFound = true
                        }
                    }
                    self.pageStatus = .failed
                }
            }
        }.store(in: &cancellable)
    }
    
    func refresh(apiModel: ApiModel) {
        cancellable.removeAll()
        pageStatus = PostsPageStatus.ready(nextPage: 1)
        notFound = false
        posts.removeAll()
        fetchPosts(apiModel: apiModel)
    }
    
    func changeSortAndTime(sort: LemmyApi.Sort, time: LemmyApi.TopTime, apiModel: ApiModel) {
        self.time = time
        changeSort(sort: sort, apiModel: apiModel)
    }
    
    func changeSort(sort: LemmyApi.Sort, apiModel: ApiModel) {
        self.sort = sort
        cancellable.removeAll()
        pageStatus = PostsPageStatus.ready(nextPage: 1)
        posts.removeAll()
        fetchPosts(apiModel: apiModel)
    }
    
    func receivePostData(title: String, content: String, url: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.createPost(title: title, content: content, url: url, communityId: communityView!.community_view.community.id) { post, _ in
            if let postView = post?.post_view {
                self.posts.insert(postView, at: 0)
                self.postCreated = true
                self.createdPost = postView
                WidgetCenter.shared.reloadTimelines(ofKind: "com.axlav.lemmios.recentPost")
            }
        }.store(in: &cancellable)
    }
    
    func follow(apiModel: ApiModel) {
        if let communityView = communityView?.community_view {
            apiModel.lemmyHttp?.follow(communityId: communityView.id, follow: communityView.subscribed == "NotSubscribed") { communityView, _ in
                self.communityView = communityView
            }.store(in: &cancellable)
        }
    }
    
    func block(apiModel: ApiModel, block: Bool) {
        if let id = communityView?.community_view.id {
            apiModel.lemmyHttp?.blockCommunity(id: id, block: block) { communityView, _ in
                if let communityView = communityView {
                    self.communityView = communityView
                }
            }.store(in: &cancellable)
        }
    }
}

enum PostsPageStatus {
    case ready(nextPage: Int)
    case loading(page: Int)
    case failed, done
}
