import Foundation
import LemmyApi
import SimpleKeychain
import SwiftUI

class WatchersModel: ObservableObject {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let simpleKeychain = SimpleKeychain()
    @AppStorage("watchers") var watchers = [StoredWatcher]()
    @AppStorage("deviceToken") var deviceToken: String?
    @Published var created = false
    @Published var error: String?

    func createWatcher(keywords: String, author: String, upvotes: Int64, community: String, instance: String) {
        let registerUrl = URL(string: baseApiUrl + "/watcher/create")!
        let payload = WatcherPayload(keywords: keywords, deviceToken: deviceToken!, author: author, upvotes: upvotes, community: community, instance: instance)

        var request = URLRequest(url: registerUrl)
        request.httpMethod = "POST"
        request.httpBody = try! encoder.encode(payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    self.error = "Unknown error creating watcher"
                    return
                }
                guard let decoded = try? self.decoder.decode(WatchersReturn.self, from: data) else {
                    if let decoded = try? self.decoder.decode(ServerError.self, from: data) {
                        self.error = String(decoded.reason.components(separatedBy: "_").joined(separator: " "))
                    }
                    return
                }
                self.watchers.append(StoredWatcher(id: decoded.id, upvotes: upvotes, author: author, keywords: keywords, communityName: community, instance: instance))
                self.created = true
            }
        }

        task.resume()
    }

    func deleteWatcher(watcher: StoredWatcher) {
        let registerUrl = URL(string: baseApiUrl + "/watcher/delete")!
        let payload = DeleteWatcherPayload(id: watcher.id)
        var request = URLRequest(url: registerUrl)
        request.httpMethod = "POST"
        request.httpBody = try! encoder.encode(payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    self.error = "Unknown error deleting watcher"
                    return
                }
                self.watchers.removeAll { $0.id == watcher.id }
            }
        }

        task.resume()
    }
}

struct ServerError: Codable {
    let error: Bool
    let reason: String
}

struct DeleteWatcherPayload: Codable {
    let id: UUID
}

struct WatcherPayload: Codable {
    let keywords: String
    let deviceToken: String
    let author: String
    let upvotes: Int64
    let community: String
    let instance: String
}

struct StoredWatcher: Codable, Identifiable {
    let id: UUID

    let upvotes: Int64

    let author: String

    let keywords: String

    let communityName: String

    let instance: String
}

struct WatchersReturn: Codable {
    let id: UUID

    let upvotes: Int64

    let author: String

    let keywords: String
}
