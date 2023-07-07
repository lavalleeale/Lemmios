import Combine
import Foundation
import SimpleKeychain
import SwiftUI

class ApiModel: ObservableObject {
    @AppStorage("serverUrl") public var url = ""
    @AppStorage("selectedAccount") var selectedAccount = ""
    @AppStorage("seen") var seen: [Int] = []
    
    @Published var lemmyHttp: LemmyHttp?
    @Published var serverSelected = false
    @Published var accounts = [StoredAccount]()
    @Published var subscribed: [String: [LemmyHttp.ApiCommunityData]]?
    
    var showAuth: (() -> Void)?
    
    private let simpleKeychain = SimpleKeychain()
    private var encoder = JSONEncoder()
    private var cancellable = Set<AnyCancellable>()
    
    init() {
        if self.url != "" {
            _ = self.selectServer(url: self.url)
        }
    }
    
    func setShowAuth(function: @escaping () -> Void) {
        self.showAuth = function
    }
    
    func getAuth() {
        self.showAuth?()
    }
    
    func selectServer(url: String) -> String {
        self.accounts = []
        do {
            self.lemmyHttp = try LemmyHttp(baseUrl: url)
            self.url = url
            self.serverSelected = true
            if try! self.simpleKeychain.hasItem(forKey: "accounts for \(url)") {
                let data = try! self.simpleKeychain.data(forKey: "accounts for \(url)")
                self.accounts = try! JSONDecoder().decode([StoredAccount].self, from: data)
                if !self.accounts.contains(where: { $0.username == selectedAccount }), !self.accounts.isEmpty {
                    self.selectedAccount = self.accounts[0].username
                } else {
                    self.selectedAccount = ""
                }
            } else {
                self.selectedAccount = ""
            }
            self.updateAuth()
        } catch LemmyHttp.LemmyError.invalidUrl {
            return "Invalid URL"
        } catch {
            return "Unknown Error"
        }
        return ""
    }
    
    func addAuth(username: String, jwt: String) {
        self.accounts.append(StoredAccount(username: username, jwt: jwt))
        try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts for \(self.url)")
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
                        self.subscribed![firstCharacter] = newArray.sorted { $0.name > $1.name }
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
        } else {
            self.lemmyHttp?.setJwt(jwt: nil)
            self.subscribed = [:]
        }
    }
    
    struct StoredAccount: Codable, Identifiable, Equatable {
        var id: String { self.jwt }
        
        let username: String
        let jwt: String
    }
}
