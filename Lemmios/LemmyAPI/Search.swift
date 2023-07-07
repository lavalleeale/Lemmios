import Foundation
import Combine

extension LemmyHttp {
    func searchCommunities(query: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, limit: Int = 20, receiveValue: @escaping (LemmyHttp.ApiCommunities?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        let query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "q", value: query), URLQueryItem(name: "type_", value: "Communities")]
        return makeRequest(path: "search", query: query, responseType: ApiCommunities.self, receiveValue: receiveValue)
    }
    
    func searchUsers(query: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, limit: Int = 20, receiveValue: @escaping (LemmyHttp.ApiUsers?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        let query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "q", value: query), URLQueryItem(name: "type_", value: "Users")]
        return makeRequest(path: "search", query: query, responseType: ApiUsers.self, receiveValue: receiveValue)
    }
    
    func searchPosts(query: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, limit: Int = 20, receiveValue: @escaping (LemmyHttp.ApiPosts?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        let query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "q", value: query), URLQueryItem(name: "type_", value: "Posts")]
        return makeRequest(path: "search", query: query, responseType: ApiPosts.self, receiveValue: receiveValue)
    }
}
extension LemmyHttp.Sort {
    var search: Bool {
        switch self {
        case .New, .Old, .Top:
            return true
        default:
            return false
        }
    }
}
