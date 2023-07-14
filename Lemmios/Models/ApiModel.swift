import Combine
import Foundation
import OSLog
import SimpleKeychain
import SwiftUI

class ApiModel: ObservableObject {
    @AppStorage("serverUrl") public var url = ""
    @AppStorage("seen") var seen: [Int] = []
    
    @Published var selectedAccount: StoredAccount?
    @Published var lemmyHttp: LemmyHttp?
    @Published var serverSelected = false
    @Published var accounts = [StoredAccount]()
    @Published var subscribed: [String: [LemmyHttp.ApiCommunityData]]?
    @Published var showingAuth = false
    @Published var unreadCount = 0
    @Published var invalidUser: String?
    @Published var siteInfo: LemmyHttp.SiteInfo?
    
    private let simpleKeychain = SimpleKeychain()
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()
    private var cancellable = Set<AnyCancellable>()
    private var serverInfoCancellable: AnyCancellable?
    
    private var timer: Timer?
    
    init() {
        if try! simpleKeychain.hasItem(forKey: "accounts") {
            let data = try! simpleKeychain.data(forKey: "accounts")
            if let decoded = try? decoder.decode([StoredAccount].self, from: data) {
                self.accounts = decoded
            }
        }
        if url != "" {
            _ = selectServer(url: url)
        }
        if let selectedAccount = UserDefaults.standard.string(forKey: "account"), let account = accounts.first(where: { selectedAccount.contains($0.instance) && selectedAccount.contains($0.username) }) {
            selectAuth(account: account)
            enablePush(account: account)
        }
    }
    
    func getAuth() {
        showingAuth = true
    }
    
    func verifyServer(url: String, receiveValue: @escaping (String?, LemmyHttp.SiteInfo?)->Void) {
        siteInfo = nil
        do {
            lemmyHttp = try LemmyHttp(baseUrl: url)
            serverInfoCancellable = lemmyHttp?.getSiteInfo { siteInfo, error in
                print(siteInfo, error)
                if let siteInfo = siteInfo {
                    receiveValue(nil, siteInfo)
                } else {
                    receiveValue("Not a lemmy server", nil)
                }
            }
        } catch LemmyHttp.LemmyError.invalidUrl {
            receiveValue("Invalid URL", nil)
        } catch {
            receiveValue("Unknown Error", nil)
        }
    }
    
    func selectServer(url: String) -> String {
        self.selectedAccount = nil
        do {
            lemmyHttp = try LemmyHttp(baseUrl: url)
            self.url = String(lemmyHttp!.baseUrl)
            if let storedAccount = UserDefaults.standard.string(forKey: "account"), !storedAccount.contains(lemmyHttp!.apiUrl.host()!) {
                UserDefaults.standard.removeObject(forKey: "account")
            }
            serverSelected = true
            if try! simpleKeychain.hasItem(forKey: "accounts for \(url)") {
                let data = try! simpleKeychain.data(forKey: "accounts for \(url)")
                accounts.append(contentsOf: try! decoder.decode([StoredAccount_OLD].self, from: data).map { StoredAccount(username: $0.username, jwt: $0.jwt, instance: lemmyHttp!.apiUrl.host()!, notificationsEnabled: $0.notificationsEnabled == true) })
                try! simpleKeychain.deleteItem(forKey: "accounts for \(url)")
                try! simpleKeychain.set(try! encoder.encode(accounts), forKey: "accounts")
            }
            updateAuth()
        } catch LemmyHttp.LemmyError.invalidUrl {
            return "Invalid URL"
        } catch {
            return "Unknown Error"
        }
        return ""
    }
    
    func addAuth(username: String, jwt: String) {
        if !accounts.contains(where: { $0.username == username && $0.instance == lemmyHttp?.apiUrl.host() }) {
            let account = StoredAccount(username: username, jwt: jwt, instance: lemmyHttp!.apiUrl.host()!, notificationsEnabled: false)
            accounts.append(account)
            try! simpleKeychain.set(try! encoder.encode(accounts), forKey: "accounts")
            lemmyHttp?.setJwt(jwt: jwt)
            selectAuth(account: account)
            enablePush(account: account)
        }
    }
    
    func enablePush(account: StoredAccount) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if error != nil {
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    self.accounts[self.accounts.firstIndex(of: account)!].notificationsEnabled = true
                    try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts")
                    #if !DEBUG
                    UserDefaults.standard.set(account.jwt, forKey: "targetJwt")
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                }
            }
        }
    }
    
    func deleteAuth(account: StoredAccount) {
        let index = accounts.firstIndex(of: account)!
        accounts.remove(at: index)
        try! simpleKeychain.set(try! encoder.encode(accounts), forKey: "accounts")
        if selectedAccount == account {
            selectedAccount = nil
            UserDefaults.standard.removeObject(forKey: "account")
            lemmyHttp?.setJwt(jwt: nil)
            unreadCount = 0
            timer?.invalidate()
        }
        if account.notificationsEnabled == true {
            let registerUrl = URL(string: "https://lemmios.lavallee.one/remove")!
            
            var request = URLRequest(url: registerUrl)
            request.httpMethod = "POST"
            request.httpBody = try! encoder.encode(["jwt": account.jwt])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data else { return }
                os_log("\(String(data: data, encoding: .utf8)!)")
            }
            
            task.resume()
        }
    }
    
    func selectAuth(account: StoredAccount) {
        _ = selectServer(url: account.instance)
        selectedAccount = account
        unreadCount = 0
        lemmyHttp?.setJwt(jwt: account.jwt)
        UserDefaults.standard.set("\(account.username)@\(account.instance)", forKey: "account")
        if let timer = timer {
            timer.fire()
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                self.lemmyHttp?.getUnreadCount { unreadCount, _ in
                    if let unreadCount = unreadCount {
                        self.unreadCount = unreadCount.replies + unreadCount.private_messages
                    }
                }.store(in: &self.cancellable)
            }
            timer!.fire()
        }
        if account.notificationsEnabled == true {
            #if !DEBUG
            UserDefaults.standard.set(account.jwt, forKey: "targetJwt")
            UIApplication.shared.registerForRemoteNotifications()
            #endif
        }
        lemmyHttp?.getSiteInfo { siteInfo, error in
            if let siteInfo = siteInfo {
                if let user = siteInfo.my_user {
                    self.subscribed = [:]
                    user.follows.map { $0.community }.forEach { community in
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
                } else {
                    self.invalidUser = account.username
                    self.deleteAuth(account: account)
                }
            }
        }.store(in: &cancellable)
    }
    
    private func updateAuth() {
        if let selectedAccount = selectedAccount {
            selectAuth(account: selectedAccount)
        } else {
            lemmyHttp?.setJwt(jwt: nil)
            subscribed = [:]
        }
    }
    
    struct StoredAccount: Codable, Identifiable, Equatable {
        static func == (lhs: StoredAccount, rhs: LemmyHttp.ApiUserData) -> Bool {
            return rhs.actor_id.pathComponents.last! == lhs.username && rhs.actor_id.host() == lhs.instance
        }
        
        static func == (lhs: LemmyHttp.ApiUserData, rhs: StoredAccount) -> Bool {
            return rhs == lhs
        }
        
        static func != (lhs: StoredAccount, rhs: LemmyHttp.ApiUserData) -> Bool {
            return !(lhs == rhs)
        }
        
        static func != (lhs: LemmyHttp.ApiUserData, rhs: StoredAccount) -> Bool {
            return !(lhs == rhs)
        }
        
        var id: String { jwt }
        
        let username: String
        let jwt: String
        let instance: String
        var notificationsEnabled: Bool
    }
    
    struct StoredAccount_OLD: Codable, Identifiable, Equatable {
        var id: String { jwt }
        
        let username: String
        let jwt: String
        var notificationsEnabled: Bool?
    }
}
