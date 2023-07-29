import Combine
import Intents
import LemmyApi
import SimpleKeychain

class IntentHandler: INExtension, CommunityIntentIntentHandling {
    private var decoder = JSONDecoder()
    func resolveCommunity(for intent: CommunityIntentIntent) async -> CommunityResolutionResult {
        if let community = intent.Community {
            return .success(with: community)
        } else {
            return .confirmationRequired(with: intent.Community)
        }
    }

    func provideCommunityOptionsCollection(for intent: CommunityIntentIntent, searchTerm: String?) async throws -> INObjectCollection<Community> {
        let keychain = SimpleKeychain(service: "com.axlav.lemmios")
        let account = UserDefaults(suiteName: "group.com.axlav.lemmios")!.string(forKey: "account")
        if let url = UserDefaults(suiteName: "group.com.axlav.lemmios")!.string(forKey: "serverUrl") {
            let lemmyApi = try LemmyApi(baseUrl: url)
            if let account = account,
               try! keychain.hasItem(forKey: "accounts"),
               let accounts = try? keychain.data(forKey: "accounts"),
               let decoded = try? decoder.decode([StoredAccount].self, from: accounts),
               let selectedAccount = decoded.first(where: { account.contains($0.username) && account.contains($0.instance) })
            {
                lemmyApi.setJwt(jwt: selectedAccount.jwt)
            }
            var cancellable: AnyCancellable?
            let (response, _) = await withCheckedContinuation { continuation in
                cancellable = lemmyApi.searchCommunities(query: searchTerm ?? "", page: 1, sort: .Hot, time: .All) { communities, error in
                    continuation.resume(returning: (communities, error))
                }
            }
            _ = cancellable
            if let response = response {
                let communities = response.communities.map { community in
                    let communityName = community.community.name
                    let host = community.community.actor_id.host()!
                    let intent = Community(identifier: "\(communityName)@\(host)", display: "\(communityName)@\(host)")
                    intent.communityName = communityName
                    intent.instance = host
                    return intent
                }
                return .init(items: communities)
            } else {
                throw CommunitiesIntentError.lemmyError
            }
        } else {
            throw CommunitiesIntentError.noSelectedServer
        }
    }

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        return self
    }
}

enum CommunitiesIntentError: String, Error {
    case noSelectedServer, lemmyError
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
