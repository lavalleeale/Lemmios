import Foundation
import Combine

class PostsModel: ObservableObject {
    private var cancellable : Set<AnyCancellable> = Set()
    private var apiModel: ApiModel
    @Published var posts = [LemmyHttp.ApiPost]()
    @Published var sort = LemmyHttp.Sort.Active
    @Published var time = LemmyHttp.TopTime.All
    @Published var pageStatus = PageStatus.ready(nextPage: 1)
    var path: String
    
    init(apiModel: ApiModel, path: String) {
        self.apiModel = apiModel
        self.path = path
    }
    
    func fetchPosts() {
        print(pageStatus)
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.getPosts(path: path, page: page, sort: sort, time: time) { posts, error in
            if (error == nil) {
                if (posts!.posts.count == 0) {
                    self.pageStatus = .done
                } else {
                    self.posts.append(contentsOf: posts!.posts)
                    self.pageStatus = .ready(nextPage: page+1)
                }
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func refresh() {
        cancellable.removeAll()
        pageStatus = PageStatus.ready(nextPage: 1)
        posts.removeAll()
        fetchPosts()
    }
    
    func changeSortAndTime(sort: LemmyHttp.Sort, time: LemmyHttp.TopTime) {
        self.time = time
        changeSort(sort: sort)
    }
    
    func changeSort(sort: LemmyHttp.Sort) {
        self.sort = sort
        cancellable.removeAll()
        pageStatus = PageStatus.ready(nextPage: 1)
        posts.removeAll()
        fetchPosts()
    }
}

enum PageStatus {
    case ready (nextPage: Int)
    case loading (page: Int)
    case failed, done
}
