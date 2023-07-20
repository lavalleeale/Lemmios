import Combine
import Intents
import LemmyApi

class IntentHandler: INExtension, CommunityIntentIntentHandling {
    func resolveCommunity(for intent: CommunityIntentIntent) async -> CommunityResolutionResult {
        if let community = intent.Community {
            return .success(with: community)
        } else {
            return .confirmationRequired(with: intent.Community)
        }
    }

    func provideCommunityOptionsCollection(for intent: CommunityIntentIntent, searchTerm: String?) async throws -> INObjectCollection<Community> {
        if let serverUrl = UserDefaults(suiteName: "group.com.axlav.lemmios")!.string(forKey: "serverUrl") {
            let lemmyApi = try LemmyApi(baseUrl: serverUrl)
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
                return .init(items: [])
//                throw CommunitiesIntentError.lemmyError
            }
        } else {
            return .init(items: [])
//            throw CommunitiesIntentError.noSelectedServer
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
