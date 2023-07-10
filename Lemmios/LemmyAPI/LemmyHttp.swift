import Combine
import Foundation
import SwiftUI

let VERSION = "v3"

class LemmyHttp {
    var apiUrl: URL
    private var cancellable: Set<AnyCancellable> = Set()
    internal var jwt: String?
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()
    
    public enum LemmyError: Swift.Error {
        case invalidUrl
    }

    init(baseUrl: String) throws {
        var baseUrl = baseUrl
        if !baseUrl.contains(/https?:\/\//) {
            baseUrl = "https://" + baseUrl
        }
        guard let apiUrl = URL(string: "\(baseUrl.replacing("/+$", with: ""))/api/\(VERSION)"), UIApplication.shared.canOpenURL(apiUrl) else {
            throw LemmyError.invalidUrl
        }
        self.apiUrl = apiUrl
        let formatter1 = DateFormatter()
        formatter1.locale = Locale(identifier: "en_US_POSIX")
        formatter1.timeZone = .gmt
        formatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        let formatter2 = DateFormatter()
        formatter2.locale = Locale(identifier: "en_US_POSIX")
        formatter2.timeZone = .gmt
        formatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            var date: Date?
            if dateStr.contains(".") {
                date = formatter1.date(from: dateStr)
            } else {
                date = formatter2.date(from: dateStr)
            }
            guard let date_ = date else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
            }
            return date_
        }
    }
    
    func setJwt(jwt: String?) {
        self.jwt = jwt
    }
    
    func makeRequestWithBody<ResponseType: Decodable, BodyType: Encodable>(path: String, query: [URLQueryItem] = [], responseType: ResponseType.Type, body: BodyType, receiveValue: @escaping (ResponseType?, NetworkError?) -> Void) -> AnyCancellable where BodyType: WithMethod {
        var url = apiUrl.appending(path: path).appending(queryItems: query)
        if jwt != nil {
            url = url.appending(queryItems: [URLQueryItem(name: "auth", value: jwt!)])
        }
        var request = URLRequest(url: url)
        request.setValue("ios:com.axlav.lemmios:v1.0.0 (by @mrlavallee@lemmy.world)", forHTTPHeaderField: "User-Agent")
        request.httpMethod = body.method
        if !(body is NoBody) {
            request.httpBody = try! encoder.encode(body)
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
                    throw NetworkError.network(code: code, description: String(data: v.data, encoding: .utf8) ?? "")
                }
                return v
            }
            .retryWithDelay(retries: 10, delay: 5, scheduler: DispatchQueue.global())
            .flatMap { v in
                Just(v.data)
                
                    // #2 try to decode data as a `Response`
                    .decode(type: ResponseType.self, decoder: self.decoder)
                
                    .mapError { NetworkError.decoding(message: String(data: v.data, encoding: .utf8) ?? "", error: $0 as! DecodingError) }
            }
            .mapError { $0 as! LemmyHttp.NetworkError }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("completed")
                    break
                case let .failure(error):
                    receiveValue(nil, error)
                }
            }, receiveValue: { value in
                receiveValue(value, nil)
            })
    }
    
    private struct NoBody: Encodable, WithMethod {
        let method = "GET"
    }
    
    func makeRequest<ResponseType: Decodable>(path: String, query: [URLQueryItem] = [], responseType: ResponseType.Type, receiveValue: @escaping (ResponseType?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: path, query: query, responseType: responseType, body: NoBody(), receiveValue: receiveValue)
    }
    
    func getUser(name: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, saved: Bool, receiveValue: @escaping (LemmyHttp.PersonView?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        var query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "username", value: name)]
        if saved {
            query.append(URLQueryItem(name: "saved_only", value: "true"))
        }
        return makeRequest(path: "user", query: query, responseType: PersonView.self, receiveValue: receiveValue)
    }
    
    func getPost(id: Int, receiveValue: @escaping (LemmyHttp.PostView?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "id", value: String(id))]
        return makeRequest(path: "post", query: query, responseType: PostView.self, receiveValue: receiveValue)
    }
    
    func getCommunity(name: String, receiveValue: @escaping (LemmyHttp.CommunityView?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "name", value: name)]
        return makeRequest(path: "community", query: query, responseType: CommunityView.self, receiveValue: receiveValue)
    }
    
    func getSiteInfo(receiveValue: @escaping (LemmyHttp.SiteInfo?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "site", query: [], responseType: SiteInfo.self, receiveValue: receiveValue)
    }
    
    func getUnreadCount(receiveValue: @escaping (LemmyHttp.UnreadCount?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "user/unread_count", query: [], responseType: UnreadCount.self, receiveValue: receiveValue)
    }
    
    func follow(communityId: Int, follow: Bool, receiveValue: @escaping (CommunityView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "community/follow", responseType: CommunityView.self, body: FollowPaylod(auth: jwt!, community_id: communityId, follow: follow), receiveValue: receiveValue)
    }
    
    func register(info: RegisterPayload, receiveValue: @escaping (AuthResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/register", responseType: AuthResponse.self, body: info, receiveValue: receiveValue)
    }
    
    func login(info: LoginPayload, receiveValue: @escaping (AuthResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/login", responseType: AuthResponse.self, body: info, receiveValue: receiveValue)
    }
    
    func getCaptcha(receiveValue: @escaping (CaptchaResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "user/get_captcha", responseType: CaptchaResponse.self, receiveValue: receiveValue)
    }
    
    func readReply(replyId: Int, read: Bool, receiveValue: @escaping (AuthResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/mark_as_read", responseType: AuthResponse.self, body: ReadPayload(auth: jwt!, comment_reply_id: replyId, read: read), receiveValue: receiveValue)
    }
    
    struct CommentReplyView: Codable {
        let comment_reply_view: Reply
    }
    
    struct ReadPayload: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let comment_reply_id: Int
        let read: Bool
    }
    
    struct Replies: Codable {
        let replies: [Reply]
    }
    
    struct ReplyOnlyData: Codable {
        var comment_reply: ReplyInfo
    }
    
    typealias Reply = Compose<ApiComment, ReplyOnlyData>
    
    struct ReplyInfo: Codable {
        var read: Bool
        let id: Int
    }
    
    struct UnreadCount: Codable {
        let replies: Int
        let mentions: Int
        let private_messages: Int
    }
    
    struct LoginPayload: Codable, WithMethod {
        let method = "POST"
        let username_or_email: String
        let password: String
        let totp_2fa_token: String?
    }
    
    struct CaptchaResponse: Codable {
        let ok: CaptchaInfo
    }
    
    struct CaptchaInfo: Codable {
        let png: String
        let uuid: String
    }
    
    struct RegisterPayload: Codable, WithMethod {
        let method = "POST"
        let username: String
        let password: String
        let password_verify: String
        let email: String
        let captcha_answer: String
        let captcha_uuid: String
        let show_nsfw = false
    }
    
    struct AuthResponse: Codable {
        let jwt: String?
        let registration_created: Bool?
        let verify_email_sent: Bool?
    }
    
    struct ErrorResponse: Codable {
        let error: String
    }
    
    struct FollowPaylod: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let community_id: Int
        let follow: Bool
    }

    enum NetworkError: Swift.Error {
        case network(code: Int, description: String)
        case decoding(message: String, error: DecodingError)
    }
    
    struct CommentView: Codable {
        let comment_view: ApiComment
    }
    
    struct PersonView: Codable, Identifiable {
        var id: Int {
            person_view.person.id
        }
        
        let person_view: ApiUser
        let comments: [ApiComment]
        let posts: [ApiPost]
    }
    
    struct ApiUser: Codable, Identifiable {
        var id: Int {
            person.id
        }

        let person: ApiUserData
        let counts: ApiUserCounts
    }
    
    struct CommunityView: Codable {
        let community_view: ApiCommunity
    }
    
    struct PostView: Codable {
        let post_view: ApiPost
    }
    
    struct ApiComment: Codable, Identifiable, WithCounts {
        var id: Int { comment.id }
        
        let comment: ApiCommentData
        let creator: ApiUserData
        let post: ApiPostData
        let counts: ApiCommentCounts
        let my_vote: Int?
        let saved: Bool?
    }
    
    struct ApiCommentData: Codable {
        let id: Int
        let content: String
        let path: String
        let ap_id: URL
    }
    
    struct ApiPost: Codable, Identifiable, WithCounts {
        var id: Int { post.id }
        
        let post: ApiPostData
        let creator: ApiUserData
        let community: ApiCommunityData
        let counts: ApiPostCounts
        let my_vote: Int?
        let saved: Bool?
    }
    
    struct ApiUserData: Codable, WithPublished, WithNameHost, Identifiable {
        let name: String
        let id: Int
        let actor_id: URL
        let published: Date
        let avatar: URL?
        
        var icon: URL? {
            avatar
        }
    }
    
    struct ApiCommunity: Codable, Identifiable {
        var id: Int { community.id }
        let community: ApiCommunityData
        let subscribed: String
        let counts: ApiCommunityCounts
    }
    
    struct ApiCommunityCounts: Codable {
        let published: Date
        let subscribers: Int
    }
    
    struct ApiCommunityData: Codable, Identifiable, WithNameHost {
        let id: Int
        let name: String
        let icon: URL?
        let actor_id: URL
    }
    
    struct ApiPostData: Codable {
        let id: Int
        let name: String
        
        let body: String?
        let thumbnail_url: URL?
        let url: URL?
        let creator_id: Int
        let nsfw: Bool
        let ap_id: URL
    }
    
    struct ApiPostCounts: Codable, WithPublished {
        let score: Int
        let comments: Int
        let published: Date
    }
    
    struct ApiCommentCounts: Codable, WithPublished {
        let score: Int
        let child_count: Int
        let published: Date
    }
    
    struct ApiUserCounts: Codable {
        let comment_score: Int
        let post_score: Int
        let comment_count: Int
        let post_count: Int
    }
    
    struct SiteInfo: Codable {
        let my_user: MyUser
    }
    
    struct MyUser: Codable {
        let follows: [Follower]
    }
    
    struct Follower: Codable {
        let community: ApiCommunityData
    }
    
    enum TopTime: String, CaseIterable, Codable {
        case Hour, SixHour, TwelveHour, Day, Week, Month, Year, All
    }
    
    enum Sort: String, CaseIterable, Codable {
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

protocol WithPublished {
    var published: Date { get }
}

protocol WithCounts: Identifiable {
    associatedtype T: WithPublished
    var counts: T { get }
    var id: Int { get }
    var saved: Bool? { get }
}

public extension Publisher {
    /**
     Creates a new publisher which will upon failure retry the upstream publisher a provided number of times, with the provided delay between retry attempts.
     If the upstream publisher succeeds the first time this is bypassed and proceeds as normal.

     - Parameters:
        - retries: The number of times to retry the upstream publisher.
        - delay: Delay in seconds between retry attempts.
        - scheduler: The scheduler to dispatch the delayed events.

     - Returns: A new publisher which will retry the upstream publisher with a delay upon failure.

     let url = URL(string: "https://api.myService.com")!

     URLSession.shared.dataTaskPublisher(for: url)
         .retryWithDelay(retries: 4, delay: 5, scheduler: DispatchQueue.global())
         .sink { completion in
             switch completion {
             case .finished:
                 print("Success 😊")
             case .failure(let error):
                 print("The last and final failure after retry attempts: \(error)")
             }
         } receiveValue: { output in
             print("Received value: \(output)")
         }
         .store(in: &cancellables)
     */
    func retryWithDelay<S>(
        retries: Int,
        delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        delayIfFailure(for: delay, scheduler: scheduler) { error in
            if let error = error as? LemmyHttp.NetworkError, case let .network(code, _) = error, code >= 400, code < 500 {
                return false
            } else {
                return true
            }
        }
        .retry(times: retries) { error in
            if let error = error as? LemmyHttp.NetworkError, case let .network(code, _) = error, code >= 400, code < 500 {
                return false
            } else {
                return true
            }
        }
        .eraseToAnyPublisher()
    }

    private func delayIfFailure<S>(
        for delay: S.SchedulerTimeType.Stride,
        scheduler: S,
        condition: @escaping (Error) -> Bool
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        return self.catch { error in
            Future { completion in
                scheduler.schedule(after: scheduler.now.advanced(by: condition(error) ? delay : 0)) {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    internal func retry(times: Int, if condition: @escaping (Failure) -> Bool) -> Publishers.RetryIf<Self> {
        Publishers.RetryIf(publisher: self, times: times, condition: condition)
    }
}

extension Publishers {
    struct RetryIf<P: Publisher>: Publisher {
        typealias Output = P.Output
        typealias Failure = P.Failure
        
        let publisher: P
        let times: Int
        let condition: (P.Failure) -> Bool
                
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            guard times > 0 else { return publisher.receive(subscriber: subscriber) }
            
            publisher.catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
                if condition(error) {
                    return RetryIf(publisher: publisher, times: times - 1, condition: condition).eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .receive(subscriber: subscriber)
        }
    }
}

protocol WithMethod {
    var method: String { get }
}

protocol WithNameHost {
    var actor_id: URL { get }
    var name: String { get }
    var icon: URL? { get }
}

@dynamicMemberLookup
struct Compose<Element1, Element2> {
    var element1: Element1
    var element2: Element2
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Element1, T>) -> T {
        get { element1[keyPath: keyPath] }
        set { element1[keyPath: keyPath] = newValue }
    }
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Element2, T>) -> T {
        get { element2[keyPath: keyPath] }
        set { element2[keyPath: keyPath] = newValue }
    }
    init(_ element1: Element1, _ element2: Element2) {
        self.element1 = element1
        self.element2 = element2
    }
}

extension Compose: Encodable where Element1: Encodable, Element2: Encodable {
    func encode(to encoder: Encoder) throws {
        try element1.encode(to: encoder)
        try element2.encode(to: encoder)
    }
}
extension Compose: Decodable where Element1: Decodable, Element2: Decodable {
    init(from decoder: Decoder) throws {
        self.element1 = try Element1(from: decoder)
        self.element2 = try Element2(from: decoder)
    }
}

extension Compose: Identifiable where Element1: Identifiable {
    var id: Element1.ID {
        self.element1.id
    }
}
