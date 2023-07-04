import Combine
import Foundation
import SwiftUI

let VERSION = "v3"

class LemmyHttp {
    private var apiUrl: URL
    private var cancellable: Set<AnyCancellable> = Set()
    private var jwt: String?
    private var encoder = JSONEncoder()
    
    public enum LemmyError: Swift.Error {
        case invalidUrl
    }

    init(baseUrl: String) throws {
        guard let apiUrl = URL(string: "\(baseUrl.replacing("/+$", with: ""))/api/\(VERSION)"), UIApplication.shared.canOpenURL(apiUrl) else {
            throw LemmyError.invalidUrl
        }
        self.apiUrl = apiUrl
    }
    
    func setJwt(jwt: String?) {
        self.jwt = jwt
    }
    
    func makeRequestWithBody<ResponseType: Decodable, BodyType: Encodable>(path: String, query: [URLQueryItem] = [], responseType: ResponseType.Type, body: BodyType) -> AnyPublisher<ResponseType, NetworkError> {
        var url = apiUrl.appending(path: path).appending(queryItems: query)
        if jwt != nil {
            url = url.appending(queryItems: [URLQueryItem(name: "auth", value: jwt!)])
        }
        var request = URLRequest(url: url)
        request.setValue("ios:com.axlav.artemis:v1.0.0 (by @mrlavallee@lemmy.world)", forHTTPHeaderField: "User-Agent")
        if !(body is NoBody) {
            request.httpBody = try! encoder.encode(body)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return URLSession.shared.dataTaskPublisher(for: request)
            // #1 URLRequest fails, throw APIError.network
            .mapError {
                NetworkError.network(code: $0.code.rawValue, description: $0.localizedDescription)
            }
            .tryMap { v in
                let code = (v.response as! HTTPURLResponse).statusCode
                if code != 200 {
                    throw NetworkError.network(code: code, description: "Lemmy Error")
                }
                return v
            }
            .flatMap { v in
                Just(v.data)
                
                    // #2 try to decode data as a `Response`
                    .decode(type: ResponseType.self, decoder: JSONDecoder())
                
                    .mapError { NetworkError.decoding(message: String(data: v.data, encoding: .utf8) ?? "", error: $0) }
            }
            .mapError { $0 as! LemmyHttp.NetworkError }
            .retry(100)
            .eraseToAnyPublisher()
    }
    
    private struct NoBody: Encodable {
        
    }
    
    func makeRequest<ResponseType: Decodable>(path: String, query: [URLQueryItem] = [], responseType: ResponseType.Type) -> AnyPublisher<ResponseType, NetworkError> {
        return makeRequestWithBody(path: path, query: query, responseType: responseType, body: NoBody())
    }
    
    func voteComment(id: Int, target: Int, receiveValue: @escaping (CommentView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/like", responseType: CommentView.self, body: CommentVote(auth: jwt!, comment_id: id, score: target))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("completed")
                    break
                case .failure(let error):
                    receiveValue(nil, error)
                }
            }, receiveValue: { value in
                receiveValue(value, nil)
            })
    }
    
    func votePost(id: Int, target: Int, receiveValue: @escaping (PostView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/like", responseType: PostView.self, body: PostVote(auth: jwt!, post_id: id, score: target))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("completed")
                    break
                case .failure(let error):
                    receiveValue(nil, error)
                }
            }, receiveValue: { value in
                receiveValue(value, nil)
            })
    }
    
    func getPosts(path: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, receiveValue: @escaping (LemmyHttp.ApiPosts?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        var query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page))]
        if path != "Home" {
            query.append(URLQueryItem(name: "community_name", value: path))
        }
        return makeRequest(path: "post/list", query: query, responseType: ApiPosts.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("completed")
                    break
                case .failure(let error):
                    receiveValue(nil, error)
                }
            }, receiveValue: { value in
                receiveValue(value, nil)
            })
    }
    
    func getComments(postId: Int, page: Int, sort: LemmyHttp.Sort, receiveValue: @escaping (LemmyHttp.ApiComments?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "sort", value: sort.rawValue), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "post_id", value: String(postId)), URLQueryItem(name: "max_depth", value: "8")]
        return makeRequest(path: "comment/list", query: query, responseType: ApiComments.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("completed")
                    break
                case .failure(let error):
                    receiveValue(nil, error)
                }
            }, receiveValue: { value in
                receiveValue(value, nil)
            })
    }

    enum NetworkError: Swift.Error {
        case network(code: Int, description: String)
        case decoding(message: String, error: Error)
    }
    
    struct ApiPosts: Codable {
        let posts: [ApiPost]
    }
    
    struct ApiComments: Codable {
        let comments: [ApiComment]
    }
    
    struct CommentView: Codable {
        let comment_view: ApiComment
    }
    
    struct CommentVote: Codable {
        let auth: String
        let comment_id: Int
        let score: Int
    }
    
    struct PostVote: Codable {
        let auth: String
        let post_id: Int
        let score: Int
    }
    
    struct PostView: Codable {
        let post_view: ApiPost
    }
    
    struct ApiComment: Codable, Identifiable {
        var id: Int { comment.id }
        
        let comment: ApiCommentData
        let creator: ApiUserData
        let post: ApiPostData
        let counts: ApiCommentCounts
        let my_vote: Int?
    }
    
    struct ApiCommentData: Codable {
        let id: Int
        let content: String
        let path: String
    }
    
    struct ApiPost: Codable, Identifiable {
        var id: Int { post.id }
        
        let post: ApiPostData
        let creator: ApiUserData
        let community: ApiCommunityData
        let counts: ApiPostCounts
        let my_vote: Int?
    }
    
    struct ApiUserData: Codable {
        let name: String
        let id: Int
        let actor_id: URL
    }
    
    struct ApiCommunityData: Codable {
        let name: String
        let icon: String?
        let actor_id: URL
    }
    
    struct ApiPostData: Codable {
        let id: Int
        let name: String
        
        let body: String?
        let thumbnail_url: String?
        let url: String?
        let creator_id: Int
    }
    
    struct ApiPostCounts: Codable {
        let score: Int
        let comments: Int
        let published: String
    }
    
    struct ApiCommentCounts: Codable {
        let score: Int
        let child_count: Int
        let published: String
    }
    
    enum TopTime: String, CaseIterable {
        case Hour, SixHour, TwelveHour, Day, Week, Month, Year, All
    }
    
    enum Sort: String, CaseIterable {
        case Hot, Active, New, Old, MostComments, NewComments, Top
        
        var image: String {
            switch self {
            case .Top: return "rosette"
            case .Hot: return "flame"
            case .New: return "clock.badge"
            case .MostComments, .NewComments: return "bubble.left.and.bubble.right"
            case .Active: return "chart.bar"
            case .Old: return "clock"
            }
        }

        var comments: Bool {
            switch self {
            case .MostComments, .NewComments, .Active: return false
            default: return true
            }
        }
        
        var hasTime: Bool {
            switch self {
            case .Top: return true
            default: return false
            }
        }
    }
}
