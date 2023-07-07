import Foundation
import Combine

class SearchedModel: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: SearchedModel, rhs: SearchedModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var communities: [LemmyHttp.ApiCommunity]?
    @Published var posts: [LemmyHttp.ApiPost]?
    @Published var users: [LemmyHttp.ApiUser]?
    @Published var sort = LemmyHttp.Sort.Active
    @Published var time = LemmyHttp.TopTime.All
    @Published var pageStatus = PostsPageStatus.ready(nextPage: 1)
    
    let query: String
    
    let searchType: SearchType
    
    init(query: String, searchType: SearchType) {
        self.query = query
        self.searchType = searchType
        switch searchType {
        case .Posts:
            self.posts = .init()
        case .Communities:
            self.communities = .init()
        case .Users:
            self.users = .init()
        }
    }
    
    func fetchCommunties(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp!.searchCommunities(query: query, page: page, sort: sort, time: time) { communities, error in
            if error == nil {
                self.communities!.append(contentsOf: communities!.communities)
                self.pageStatus = .ready(nextPage: page+1)
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func fetchPosts(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp!.searchPosts(query: query, page: page, sort: sort, time: time) { posts, error in
            if error == nil {
                self.posts!.append(contentsOf: posts!.posts)
                self.pageStatus = .ready(nextPage: page+1)
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func fetchUsers(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp!.searchUsers(query: query, page: page, sort: sort, time: time) { users, error in
            if error == nil {
                self.users!.append(contentsOf: users!.users)
                self.pageStatus = .ready(nextPage: page+1)
            } else {
                print(error)
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func changeSortAndTime(sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, apiModel: ApiModel) {
        self.time = time
        changeSort(sort: sort, apiModel: apiModel)
    }
    
    func changeSort(sort: LemmyHttp.Sort, apiModel: ApiModel) {
        self.sort = sort
        cancellable.removeAll()
        pageStatus = PostsPageStatus.ready(nextPage: 1)
        switch searchType {
        case .Posts:
            posts!.removeAll()
            fetchPosts(apiModel: apiModel)
        case .Communities:
            communities!.removeAll()
            fetchCommunties(apiModel: apiModel)
        case .Users:
            users!.removeAll()
            fetchUsers(apiModel: apiModel)
        }
    }
    
    enum SearchType: String, CaseIterable {
        case Posts, Communities, Users
    }
}
