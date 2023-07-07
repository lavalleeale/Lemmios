import Combine
import Foundation

extension LemmyHttp {
    func getPosts(path: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, receiveValue: @escaping (LemmyHttp.ApiPosts?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        var query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page))]
        if path == "Subscribed" {
            if self.jwt != nil {
                query.append(URLQueryItem(name: "type_", value: "Subscribed"))
            }
        } else if path != "All" && path != "" {
            query.append(URLQueryItem(name: "community_name", value: path))
        }
        return makeRequest(path: "post/list", query: query, responseType: ApiPosts.self, receiveValue: receiveValue)
    }

    func getComments(postId: Int, parentId: Int? = nil, sort: LemmyHttp.Sort, receiveValue: @escaping (LemmyHttp.ApiComments?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var query = [URLQueryItem(name: "sort", value: sort.rawValue), URLQueryItem(name: "post_id", value: String(postId)), URLQueryItem(name: "max_depth", value: "8"), URLQueryItem(name: "type_", value: "All")]
        if let parentId = parentId {
            query.append(URLQueryItem(name: "parent_id", value: String(parentId)))
        }
        return makeRequest(path: "comment/list", query: query, responseType: ApiComments.self, receiveValue: receiveValue)
    }
    
    func getCommunities(page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, limit: Int = 10, receiveValue: @escaping (LemmyHttp.ApiCommunities?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        let query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
        return makeRequest(path: "community/list", query: query, responseType: ApiCommunities.self, receiveValue: receiveValue)
    }

    struct ApiComments: Codable {
        let comments: [ApiComment]
    }
    
    struct ApiPosts: Codable {
        let posts: [ApiPost]
    }
    
    struct ApiCommunities: Codable {
        let communities: [ApiCommunity]
    }
    
    struct ApiUsers: Codable {
        let users: [ApiUser]
    }
}
