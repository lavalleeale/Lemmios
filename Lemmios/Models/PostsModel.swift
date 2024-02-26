import Combine
import Foundation
import LemmyApi
import LinkPreview
import SwiftUI
import WidgetKit

class PostsModel: ObservableObject, Hashable, PostDataReceiver {
    private var id = UUID()
    
    static func == (lhs: PostsModel, rhs: PostsModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var posts = [LemmyApi.PostView]()
    @Published var sort = LemmyApi.Sort.Active
    @Published var time = LemmyApi.TopTime.All
    @Published var pageStatus = PostsSpecificPageStatus.readyInt(nextPage: 1)
    @Published var skipped = 0
    @Published var communityView: LemmyApi.CommunityView?
    @Published var postCreated = false
    @Published var createdPost: LemmyApi.PostView?
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
        if posts.isEmpty && !specialPostPathList.contains(path) {
            apiModel.lemmyHttp?.getCommunity(name: path) { posts, _ in
                if let posts = posts {
                    self.communityView = posts
                }
            }.store(in: &cancellable)
        }
        if case let .readyInt(page) = pageStatus {
            pageStatus = .loadingInt(page: page)
            apiModel.lemmyHttp?.getPosts(path: path, page: page, sort: sort, time: time, receiveValue: handlePosts(apiModel: apiModel)).store(in: &cancellable)
        } else if case let .readyCursor(page) = pageStatus {
            pageStatus = .loadingCursor
            apiModel.lemmyHttp?.getPosts(path: path, pageCursor: page, sort: sort, time: time, receiveValue: handlePosts(apiModel: apiModel)).store(in: &cancellable)
        }
    }
    
    func handlePosts(apiModel: ApiModel) -> ((LemmyApi.ApiPosts?, LemmyApi.NetworkError?) -> Void) {
        return { (posts: LemmyApi.ApiPosts?, error: LemmyApi.NetworkError?) in
            DispatchQueue.main.async {
                if let posts = posts {
                    if posts.posts.isEmpty {
                        self.pageStatus = .done
                    } else {
                        let postList = posts.posts.filter { post in
                            let shouldHide = (self.hideRead && self.enableRead && DBModel.instance.isRead(postId: post.id)) || self.filters.map { post.post.name.lowercased().contains($0.lowercased()) }.contains(true) || self.posts.contains { $0.post.id == post.id }
                            if shouldHide {
                                self.skipped += 1
                            }
                            return !shouldHide
                        }
                        for post in postList {
                            if let url = post.post.thumbnail_url, let pathExtension = post.post.UrlData?.pathExtension, imageExtensions.contains(pathExtension) {
                                let request = URLRequest(url: url)
                                let config = URLSessionConfiguration.default
                                config.urlCache = .imageCache
                                URLSession(configuration: config)
                                    .dataTask(with: request)
                                    .resume()
                            } else if let url = post.post.UrlData, MetadataStorage.metadata(for: url) == nil {
                                MetadataStorage.getMetadata(url: url) { metadata in
                                    if let metadata = metadata {
                                        MetadataStorage.store(metadata)
                                    }
                                }
                            }
                        }
                        self.posts.append(contentsOf: postList)
                        if let nextPage = posts.next_page {
                            self.pageStatus = .readyCursor(nextPage: nextPage)
                        } else {
                            if case let .loadingInt(page) = self.pageStatus {
                                self.pageStatus = .readyInt(nextPage: page + 1)
                            }
                        }
                        if postList.isEmpty {
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
        }
    }
    
    func refresh(apiModel: ApiModel) {
        cancellable.removeAll()
        pageStatus = PostsSpecificPageStatus.readyInt(nextPage: 1)
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
        pageStatus = PostsSpecificPageStatus.readyInt(nextPage: 1)
        posts.removeAll()
        fetchPosts(apiModel: apiModel)
    }
    
    func hideReadPosts() {
        posts = posts.filter { !DBModel.instance.isRead(postId: $0.id) }
    }
    
    func receivePostData(title: String, content: String, url: String, apiModel: ApiModel) {
        if let communityView = communityView {
            apiModel.lemmyHttp?.createPost(title: title, content: content, url: url, communityId: communityView.community_view.community.id) { post, _ in
                if let postView = post?.post_view {
                    self.posts.insert(postView, at: 0)
                    self.postCreated = true
                    self.createdPost = postView
                    WidgetCenter.shared.reloadTimelines(ofKind: "com.axlav.lemmios.recentPost")
                }
            }.store(in: &cancellable)
        }
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

enum PostsSpecificPageStatus {
    case readyCursor(nextPage: String)
    case readyInt(nextPage: Int)
    case loadingInt(page: Int)
    case loadingCursor, failed, done
    
    var isLoading: Bool {
        switch self {
        case let .loadingInt(page):
            return true
        case .loadingCursor:
            return true
        default:
            return false
        }
    }
}

enum PostsPageStatus {
    case ready(nextPage: Int)
    case loading(page: Int)
    case failed, done
}
