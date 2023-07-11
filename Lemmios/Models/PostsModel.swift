import Combine
import Foundation

class PostsModel: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: PostsModel, rhs: PostsModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var posts = [LemmyHttp.ApiPost]()
    @Published var sort = LemmyHttp.Sort.Active
    @Published var time = LemmyHttp.TopTime.All
    @Published var pageStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var communityView: LemmyHttp.CommunityView?
    @Published var postCreated = false
    @Published var createdPost: LemmyHttp.ApiPost?
    @Published var notFound = false
    var path: String
    
    init(path: String) {
        self.path = path
        if let defaultPostSort = UserDefaults.standard.string(forKey: "defaultPostSort") {
            self.sort = LemmyHttp.Sort(rawValue: defaultPostSort)!
        }
        if let defaultPostSortTime = UserDefaults.standard.string(forKey: "defaultPostSortTime") {
            self.time = LemmyHttp.TopTime(rawValue: defaultPostSortTime)!
        }
    }
    
    func fetchPosts(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        if posts.isEmpty && !specialPostPathList.contains(self.path) {
            apiModel.lemmyHttp?.getCommunity(name: self.path) { posts, error in
                if let posts = posts {
                    self.communityView = posts
                }
            }.store(in: &cancellable)
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp?.getPosts(path: path, page: page, sort: sort, time: time) { posts, error in
            if let posts = posts {
                if posts.posts.isEmpty {
                    self.pageStatus = .done
                } else {
                    self.posts.append(contentsOf: posts.posts)
                    self.pageStatus = .ready(nextPage: page + 1)
                }
            } else {
                if case let .network(code, _) = error! {
                    if code == 404 {
                        self.notFound = true
                    }
                }
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func refresh(apiModel: ApiModel) {
        cancellable.removeAll()
        pageStatus = PostsPageStatus.ready(nextPage: 1)
        posts.removeAll()
        fetchPosts(apiModel: apiModel)
    }
    
    func changeSortAndTime(sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, apiModel: ApiModel) {
        self.time = time
        changeSort(sort: sort, apiModel: apiModel)
    }
    
    func changeSort(sort: LemmyHttp.Sort, apiModel: ApiModel) {
        self.sort = sort
        cancellable.removeAll()
        pageStatus = PostsPageStatus.ready(nextPage: 1)
        posts.removeAll()
        fetchPosts(apiModel: apiModel)
    }
    
    func createPost(type: PostType, title: String, content: String, apiModel: ApiModel) {
        apiModel.lemmyHttp?.createPost(type: type, title: title, content: content, communityId: communityView!.community_view.community.id) { post, error in
            if let postView = post?.post_view {
                self.posts.insert(postView, at: 0)
                self.postCreated = true
                self.createdPost = postView
            }
        }.store(in: &cancellable)
    }
    
    func follow(apiModel: ApiModel) {
        apiModel.lemmyHttp?.follow(communityId: communityView!.community_view.id, follow: communityView!.community_view.subscribed == "NotSubscribed") { communityView, error in
            self.communityView = communityView
        }.store(in: &cancellable)
    }
}

enum PostsPageStatus {
    case ready(nextPage: Int)
    case loading(page: Int)
    case failed, done
}
