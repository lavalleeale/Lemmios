import Combine
import Foundation
import LemmyApi
import OSLog
import SwiftUI

class SearchedModel: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: SearchedModel, rhs: SearchedModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private var cancellable: Set<AnyCancellable> = Set()
    @Published var communities: [LemmyApi.ApiCommunity]?
    @Published var posts: [LemmyApi.PostView]?
    @Published var users: [LemmyApi.ApiUser]?
    @Published var sort = LemmyApi.Sort.Top
    @Published var time = LemmyApi.TopTime.All
    @Published var pageStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var rateLimited = false
    
    @Published var query: String
    
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
    
    func reset(removeResults: Bool) {
        if removeResults {
            switch searchType {
            case .Posts:
                posts?.removeAll()
            case .Communities:
                communities?.removeAll()
            case .Users:
                users?.removeAll()
            }
        }
        pageStatus = .ready(nextPage: 1)
        cancellable.removeAll()
    }
    
    func fetchCommunties(apiModel: ApiModel, reset: Bool = false) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp?.searchCommunities(query: query, page: page, sort: sort, time: time) { communities, error in
            if let communities = communities?.communities {
                if communities.isEmpty {
                    self.pageStatus = .done
                    return
                }
                if reset {
                    self.communities = communities
                } else {
                    self.communities!.append(contentsOf: communities)
                }
                self.pageStatus = .ready(nextPage: page+1)
            } else if let error = error {
                if case let .lemmyError(message: message, code: _) = error {
                    if message == "rate_limit_error" {
                        self.rateLimited = true
                    }
                }
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func fetchPosts(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp?.searchPosts(query: query, page: page, sort: sort, time: time) { posts, error in
            DispatchQueue.main.async {
                if error == nil {
                    if posts!.posts.isEmpty {
                        self.pageStatus = .done
                        return
                    }
                    self.posts!.append(contentsOf: posts!.posts.filter { _ in true })
                    self.pageStatus = .ready(nextPage: page+1)
                } else if let error = error {
                    if case let .lemmyError(message: message, code: _) = error {
                        if message == "rate_limit_error" {
                            self.rateLimited = true
                        }
                    }
                    self.pageStatus = .failed
                }
            }
        }.store(in: &cancellable)
    }
    
    func fetchUsers(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp?.searchUsers(query: query, page: page, sort: sort, time: time) { users, error in
            if error == nil {
                if users!.users.isEmpty {
                    self.pageStatus = .done
                    return
                }
                self.users!.append(contentsOf: users!.users)
                self.pageStatus = .ready(nextPage: page+1)
            } else if let error = error {
                if case let .lemmyError(message: message, code: _) = error {
                    if message == "rate_limit_error" {
                        self.rateLimited = true
                    }
                }
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
    
    func changeSortAndTime(sort: LemmyApi.Sort, time: LemmyApi.TopTime, apiModel: ApiModel) {
        self.time = time
        changeSort(sort: sort, apiModel: apiModel)
    }
    
    func changeSort(sort: LemmyApi.Sort, apiModel: ApiModel) {
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
