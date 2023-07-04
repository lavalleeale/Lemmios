import Combine
import Foundation
import SimpleKeychain
import SwiftUI

class ApiModel: ObservableObject {
    private var lemmyHttp: LemmyHttp?
    @Published var serverSelected = false
    @AppStorage("serverUrl") public var url = ""
    private let simpleKeychain = SimpleKeychain()
    @AppStorage("selectedAccount") var selectedAccount = ""
    @Published var accounts = [StoredAccount]()
    private var encoder = JSONEncoder()
    var showAuth: (()->Void)?
    
    init() {
        if self.url != "" {
            _ = (self.selectServer(url: self.url) == "")
        }
        if try! self.simpleKeychain.hasItem(forKey: "accounts") {
            let data = try! self.simpleKeychain.data(forKey: "accounts")
            self.accounts = try! JSONDecoder().decode([StoredAccount].self, from: data)
            self.updateAuth()
        }
    }
    
    func setShowAuth(function: @escaping ()->Void) {
        showAuth = function
    }
    
    func getAuth() {
        showAuth?()
    }
    
    func selectServer(url: String) -> String {
        do {
            self.lemmyHttp = try LemmyHttp(baseUrl: url)
            self.url = url
            self.serverSelected = true
        } catch LemmyHttp.LemmyError.invalidUrl {
            return "Invalid URL"
        } catch {
            return "Unknown Error"
        }
        return ""
    }
    
    func addAuth(username: String, jwt: String) {
        self.accounts.append(StoredAccount(username: username, jwt: jwt))
        try! self.simpleKeychain.set(try! encoder.encode(self.accounts), forKey: "accounts")
        self.lemmyHttp?.setJwt(jwt: jwt)
        self.selectedAccount = username
    }
    
    func deleteAuth(username: String) {
        self.accounts.removeAll {$0.username == username}
        try! self.simpleKeychain.set(try! encoder.encode(self.accounts), forKey: "accounts")
        if (self.selectedAccount == username) {
            self.selectedAccount = ""
            self.lemmyHttp?.setJwt(jwt: nil)
        }
    }
    
    func selectAuth(username: String) {
        self.selectedAccount = username
        self.lemmyHttp?.setJwt(jwt: self.accounts.first { $0.username == username }!.jwt)
    }
    
    private func updateAuth() {
        if (self.selectedAccount != "") {
            selectAuth(username: self.selectedAccount)
        }
    }
    
    func getPosts(path: String, page: Int, sort: LemmyHttp.Sort, time: LemmyHttp.TopTime, receiveValue: @escaping (LemmyHttp.ApiPosts?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        lemmyHttp!.getPosts(path: path, page: page, sort: sort, time: time, receiveValue: receiveValue)
    }
    
    func getComments(postId: Int, page: Int, sort: LemmyHttp.Sort, receiveValue: @escaping (LemmyHttp.ApiComments?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        lemmyHttp!.getComments(postId: postId, page: page, sort: sort, receiveValue: receiveValue)
    }
    
    func votePost(id: Int, target: Int, receiveValue: @escaping (LemmyHttp.PostView?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        lemmyHttp!.votePost(id: id, target: target, receiveValue: receiveValue)
    }
    
    func voteComment(id: Int, target: Int, receiveValue: @escaping (LemmyHttp.CommentView?, LemmyHttp.NetworkError?) -> Void) -> AnyCancellable {
        lemmyHttp!.voteComment(id: id, target: target, receiveValue: receiveValue)
    }
    
    struct StoredAccount: Codable, Identifiable {
        var id: String { self.jwt }
        
        let username: String
        let jwt: String
    }
}
