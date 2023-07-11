import Combine
import Foundation
import OSLog
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
    @Published var showingAuth = false
    @Published var unreadCount = 0
    @Published var invalidUser: String?
    
    private let simpleKeychain = SimpleKeychain()
    private var encoder = JSONEncoder()
    private var cancellable = Set<AnyCancellable>()
    
    private var timer: Timer?
    
    init() {
        if self.url != "" {
            _ = self.selectServer(url: self.url)
        }
    }
    
    func getAuth() {
        self.showingAuth = true
    }
    
    func selectServer(url: String) -> String {
        self.accounts = []
        do {
            self.lemmyHttp = try LemmyHttp(baseUrl: url)
            // /api/v3
            self.url = String(self.lemmyHttp!.apiUrl.absoluteString.dropLast(7))
            self.serverSelected = true
            if try! self.simpleKeychain.hasItem(forKey: "accounts for \(url)") {
                let data = try! self.simpleKeychain.data(forKey: "accounts for \(url)")
                self.accounts = try! JSONDecoder().decode([StoredAccount].self, from: data)
                if self.accounts.isEmpty {
                    self.selectedAccount = ""
                } else if !self.accounts.contains(where: { $0.username == selectedAccount }) {
                    self.selectedAccount = self.accounts[0].username
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
        if !self.accounts.contains(where: { $0.username == username }) {
            self.accounts.append(StoredAccount(username: username, jwt: jwt))
            try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts for \(self.url)")
            self.lemmyHttp?.setJwt(jwt: jwt)
            self.selectAuth(username: username, showSubscribe: true)
            self.enablePush(username: username)
        }
    }
    
    func enablePush(username: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if error != nil {
                return
            }
            
            if granted, let account = self.accounts.first { $0.username == username } {
                UserDefaults.standard.set(account.jwt, forKey: "targetJwt")
                DispatchQueue.main.async {
                    self.accounts[self.accounts.firstIndex { $0.username == username }!].notificationsEnabled = true
                    try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts for \(self.url)")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func deleteAuth(username: String) {
        let index = self.accounts.firstIndex { $0.username == username }!
        let account = self.accounts[index]
        self.accounts.remove(at: index)
        try! self.simpleKeychain.set(try! self.encoder.encode(self.accounts), forKey: "accounts for \(self.url)")
        if self.selectedAccount == username {
            self.selectedAccount = ""
            self.lemmyHttp?.setJwt(jwt: nil)
            self.unreadCount = 0
            self.timer?.invalidate()
        }
        if account.notificationsEnabled == true {
            let registerUrl = URL(string: "https://lemmios.lavallee.one/remove")!
            
            var request = URLRequest(url: registerUrl)
            request.httpMethod = "POST"
            request.httpBody = try! self.encoder.encode(["jwt": account.jwt])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data else { return }
                os_log("\(String(data: data, encoding: .utf8)!)")
            }
            
            task.resume()
        }
    }
    
    func selectAuth(username: String, showSubscribe: Bool = false) {
        self.selectedAccount = username
        let account = self.accounts.first { $0.username == username }!
        self.unreadCount = 0
        self.lemmyHttp?.setJwt(jwt: account.jwt)
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
            UserDefaults.standard.set(account.jwt, forKey: "targetJwt")
            UIApplication.shared.registerForRemoteNotifications()
        }
        self.lemmyHttp?.getSiteInfo { siteInfo, error in
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
            } else if case let .decoding(_, error) = error {
                if (error as CustomDebugStringConvertible).debugDescription.contains("my_user") {
                    self.invalidUser = self.selectedAccount
                    self.deleteAuth(username: self.selectedAccount)
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
        var jwt: String
        var notificationsEnabled: Bool?
    }
}
