import Foundation

let removeGlobalRegex = /"global"(.|\n)*},/

class ApolloImportModel: ObservableObject {
    private let decoder = JSONDecoder()

    func read(from url: URL) -> [String: ApolloUserData]? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let string = try String(contentsOf: url)
            let data = string.replacing(removeGlobalRegex, with: "").data(using: .utf8)!
            return try decoder.decode([String: ApolloUserData].self, from: data)
        } catch {
            return nil
        }
    }
}

struct ApolloUserData: Codable, Hashable {
    let subscribed_subreddits: [String]
}

struct SubMap: Codable {
    let name: String
    let links: [SubMapLink]
}

struct SubMapLink: Codable {
    let service: String
    let url: URL
    let official: Bool?
}
