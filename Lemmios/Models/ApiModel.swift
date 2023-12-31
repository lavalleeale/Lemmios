import Combine
import Foundation
import LemmyApi
import OSLog
import SimpleKeychain
import SwiftUI
import WidgetKit

class ApiModel: ObservableObject {
    @AppStorage("serverUrl", store: .init(suiteName: "group.com.axlav.lemmios")) public var url = ""
    @AppStorage("seen") var seen: [Int] = []
    
    @Published var selectedAccount: StoredAccount?
    @Published var lemmyHttp: LemmyApi?
    @Published var serverSelected = false
    @Published var accounts = [StoredAccount]()
    @Published var subscribed: [String: [LemmyApi.Community]]?
    @Published var moderates: [LemmyApi.Community]?
    @Published var showingAuth = false
    @Published var invalidUser: String?
    @Published var siteInfo: LemmyApi.SiteInfo?
    @Published var nsfw = false
    
    private let simpleKeychain = SimpleKeychain()
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()
    private var cancellable = Set<AnyCancellable>()
    private var serverInfoCancellable: AnyCancellable?
    private var deviceTokenCancellable: AnyCancellable?
    
    init(doNothing: Bool) {}
    
    init() {
        if let url = UserDefaults.standard.string(forKey: "serverUrl") {
            self.url = url
            UserDefaults.standard.removeObject(forKey: "serverUrl")
        }
        if try! simpleKeychain.hasItem(forKey: "accounts") {
            let data = try! simpleKeychain.data(forKey: "accounts")
            if let decoded = try? decoder.decode([StoredAccount].self, from: data) {
                self.accounts = decoded
            }
        }
        if url != "" {
            _ = selectServer(url: url)
        }
        if let oldSelected = UserDefaults.standard.string(forKey: "account") {
            UserDefaults(suiteName: "group.com.axlav.lemmios")!.set(oldSelected, forKey: "account")
            UserDefaults.standard.removeObject(forKey: "account")
        }
        if let selectedAccount = UserDefaults(suiteName: "group.com.axlav.lemmios")!.string(forKey: "account"), let account = accounts.first(where: { selectedAccount.contains($0.instance) && selectedAccount.contains($0.username) }) {
            selectAuth(account: account)
        }
    }
    
    func getAuth() {
        showingAuth = true
    }
    
    func verifyServer(url: String, receiveValue: @escaping (String?, LemmyApi.SiteInfo?) -> Void) {
        siteInfo = nil
        do {
            let lemmyHttp = try LemmyApi(baseUrl: url)
            serverInfoCancellable = lemmyHttp.getSiteInfo { siteInfo, error in
                if let siteInfo = siteInfo {
                    receiveValue(nil, siteInfo)
                } else {
                    receiveValue("Not a lemmy server", nil)
                }
            }
        } catch LemmyApi.LemmyError.invalidUrl {
            receiveValue("Invalid URL", nil)
        } catch {
            receiveValue("Unknown Error", nil)
        }
    }
    
    func selectServer(url: String) -> String {
        selectedAccount = nil
        do {
            lemmyHttp = try LemmyApi(baseUrl: url)
            if let storedAccount = UserDefaults(suiteName: "group.com.axlav.lemmios")!.string(forKey: "account"), !storedAccount.contains(lemmyHttp!.apiUrl.host()!) {
                UserDefaults(suiteName: "group.com.axlav.lemmios")!.removeObject(forKey: "account")
            }
            self.url = String(lemmyHttp!.baseUrl)
            serverSelected = true
            if try! simpleKeychain.hasItem(forKey: "accounts for \(url)") {
                let data = try! simpleKeychain.data(forKey: "accounts for \(url)")
                accounts.append(contentsOf: try! decoder.decode([StoredAccount_OLD].self, from: data).map { StoredAccount(username: $0.username, jwt: $0.jwt, instance: lemmyHttp!.apiUrl.host()!, notificationsEnabled: $0.notificationsEnabled == true) })
                try! simpleKeychain.deleteItem(forKey: "accounts for \(url)")
                try! simpleKeychain.set(try! encoder.encode(accounts), forKey: "accounts")
            }
            updateAuth()
        } catch LemmyApi.LemmyError.invalidUrl {
            return "Invalid URL"
        } catch {
            return "Unknown Error"
        }
        return ""
    }
    
    func addAuth(username: String, jwt: String) {
        if !accounts.contains(where: { $0.username == username && $0.instance == lemmyHttp?.apiUrl.host() }) {
            let account = StoredAccount(username: username, jwt: jwt, instance: lemmyHttp!.apiUrl.host()!, notificationsEnabled: true)
            accounts.append(account)
            try! simpleKeychain.set(try! encoder.encode(accounts), forKey: "accounts")
            lemmyHttp?.setJwt(jwt: jwt)
            selectAuth(account: account)
            selectedAccount = account
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
                    self.deviceTokenCancellable = UserDefaults.standard.publisher(for: \.deviceToken)
                        .sink { newValue in
                            self.deviceTokenCancellable = nil
                            let registerUrl = URL(string: baseApiUrl + "/user/register")!
                           
                            var request = URLRequest(url: registerUrl)
                            request.httpMethod = "POST"
                            request.httpBody = try! JSONEncoder().encode(["jwt": account.jwt, "instance": account.instance, "deviceToken": newValue])
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                           
                            let task = URLSession.shared.dataTask(with: request) { data, _, _ in
                                guard let data = data else { return }
                                os_log("\(String(data: data, encoding: .utf8)!)")
                            }
                           
                            task.resume()
                        }
                    UIApplication.shared.registerForRemoteNotifications()
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
            UserDefaults(suiteName: "group.com.axlav.lemmios")!.removeObject(forKey: "account")
            lemmyHttp?.setJwt(jwt: nil)
        }
        if account.notificationsEnabled == true {
            disablePush(account: account)
        }
    }
    
    func disablePush(account: StoredAccount) {
        let registerUrl = URL(string: baseApiUrl + "/user/remove")!
        
        var request = URLRequest(url: registerUrl)
        request.httpMethod = "POST"
        request.httpBody = try! encoder.encode(["jwt": account.jwt])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            os_log("\(String(data: data, encoding: .utf8)!)")
        }
        
        if let index = accounts.firstIndex(of: account) {
            accounts[index].notificationsEnabled = false
            try! simpleKeychain.set(try! encoder.encode(accounts), forKey: "accounts")
        }
        
        task.resume()
    }
    
    func selectAuth(account: StoredAccount) {
        _ = selectServer(url: account.instance)
        selectedAccount = account
        lemmyHttp?.setJwt(jwt: account.jwt)
        UserDefaults(suiteName: "group.com.axlav.lemmios")!.set("\(account.username)@\(account.instance)", forKey: "account")
        WidgetCenter.shared.reloadTimelines(ofKind: "com.axlav.lemmios.recentPost")
        WidgetCenter.shared.reloadTimelines(ofKind: "com.axlav.lemmios.recentCommunity")
        if account.notificationsEnabled == true {
            enablePush(account: account)
        }
        lemmyHttp?.getSiteInfo { siteInfo, _ in
            if let siteInfo = siteInfo {
                if let user = siteInfo.my_user {
                    self.nsfw = user.local_user_view?.local_user?.show_nsfw ?? false
                    self.moderates = user.moderates.map { $0.community }
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
            moderates = []
            nsfw = false
        }
    }
    
    struct StoredAccount: Codable, Identifiable, Equatable {
        static func == (lhs: StoredAccount, rhs: LemmyApi.Person) -> Bool {
            return rhs.actor_id.pathComponents.last! == lhs.username && rhs.actor_id.host() == lhs.instance
        }
        
        static func == (lhs: LemmyApi.Person, rhs: StoredAccount) -> Bool {
            return rhs == lhs
        }
        
        static func != (lhs: StoredAccount, rhs: LemmyApi.Person) -> Bool {
            return !(lhs == rhs)
        }
        
        static func != (lhs: LemmyApi.Person, rhs: StoredAccount) -> Bool {
            return !(lhs == rhs)
        }
        
        static func == (lhs: StoredAccount, rhs: StoredAccount) -> Bool {
            lhs.jwt == rhs.jwt
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
