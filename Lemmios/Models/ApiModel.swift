import Combine
import Foundation
import SimpleKeychain
import SwiftUI

class ApiModel: ObservableObject {
    @Published var lemmyHttp: LemmyHttp?
    @Published var serverSelected = false
    @AppStorage("serverUrl") public var url = ""
    private let simpleKeychain = SimpleKeychain()
    @AppStorage("selectedAccount") var selectedAccount = ""
    @Published var accounts = [StoredAccount]()
    @Published var subscribed: [String: [LemmyHttp.ApiCommunityData]]?
    private var encoder = JSONEncoder()
    private var cancellable = Set<AnyCancellable>()
    var showAuth: (() -> Void)?
    
    init() {
        if self.url != "" {
            if (self.selectServer(url: self.url) == "") {
                if try! self.simpleKeychain.hasItem(forKey: "accounts for \(url)") {
                    let data = try! self.simpleKeychain.data(forKey: "accounts for \(url)")
                    self.accounts = try! JSONDecoder().decode([StoredAccount].self, from: data)
                    self.updateAuth()
                }
            }
        }
    }
    
    func setShowAuth(function: @escaping () -> Void) {
        self.showAuth = function
    }
    
    func getAuth() {
        self.showAuth?()
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
        try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts for \(url)")
        self.lemmyHttp?.setJwt(jwt: jwt)
        self.selectedAccount = username
    }
    
    func deleteAuth(username: String) {
        self.accounts.removeAll { $0.username == username }
        try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts")
        if self.selectedAccount == username {
            self.selectedAccount = ""
            self.lemmyHttp?.setJwt(jwt: nil)
        }
    }
    
    func selectAuth(username: String) {
        self.selectedAccount = username
        self.lemmyHttp!.setJwt(jwt: self.accounts.first { $0.username == username }!.jwt)
        self.lemmyHttp!.getSiteInfo { siteInfo, _ in
            if let siteInfo = siteInfo {
                self.subscribed = [:]
                siteInfo.my_user.follows.map { $0.community }.forEach { community in
                    let nameString = community.name
                    let firstCharacter = nameString.first!.uppercased()
                    
                    if let array = self.subscribed![firstCharacter] {
                        var newArray = array
                        newArray.append(community)
                        self.subscribed![firstCharacter] = newArray.sorted {$0.name > $1.name}
                    } else {
                        self.subscribed![firstCharacter] = [community]
                    }
                }
            }
        }.store(in: &self.cancellable)
    }
    
    private func updateAuth() {
        if self.selectedAccount != "" {
            self.selectAuth(username: self.selectedAccount)
        }
    }
    
    struct StoredAccount: Codable, Identifiable {
        var id: String { self.jwt }
        
        let username: String
        let jwt: String
    }
}
