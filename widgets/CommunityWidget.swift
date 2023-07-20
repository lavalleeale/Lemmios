import Combine
import Foundation
import LemmyApi
import SimpleKeychain
import SwiftUI
import WidgetKit

struct CommunityProvider: IntentTimelineProvider {
    typealias Entry = SimpleEntry
    internal var decoder = JSONDecoder()
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), posts: [])
    }

    func getSnapshot(for configuration: CommunityIntentIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let keychain = SimpleKeychain(service: "com.axlav.lemmios")
        let account = UserDefaults(suiteName: "group.com.axlav.lemmios")!.string(forKey: "account")
        if let account = account,
           try! keychain.hasItem(forKey: "accounts"),
           let accounts = Optional(try! keychain.data(forKey: "accounts")),
           let decoded = Optional(try! decoder.decode([StoredAccount].self, from: accounts)),
           let selectedAccount = decoded.first(where: { account.contains($0.username) && account.contains($0.instance) })
        {
            Task {
                completion(await getPosts(instance: configuration.Community?.instance ?? "sh.itjust.works", community: configuration.Community?.communityName ?? "All", jwt: selectedAccount.jwt, context: context))
            }
        } else {
            completion(SimpleEntry(date: .now, posts: []))
        }
    }

    func getPosts(instance: String, community: String, jwt: String, context: Context) async -> SimpleEntry {
        let lemmyApi = try! LemmyApi(baseUrl: instance)
        lemmyApi.jwt = jwt
        var cancellable: AnyCancellable?
        let (response, _) = await withCheckedContinuation { continuation in
            cancellable = lemmyApi.getPosts(path: community, page: 1, sort: .Hot, time: .All) { user, error in
                continuation.resume(returning: (user, error))
            }
        }
        _ = cancellable
        guard let posts = response?.posts else {
            return SimpleEntry(date: .now, posts: [])
        }
        let maxIndex = getTargetNum(context.family)
        var widgetPostInfos: [WidgetInfo] = []
        for index in 0 ... min(maxIndex, posts.endIndex - 1) {
            var image: UIImage?
            if let url = posts[index].post.url, imageExtensions.contains(url.pathExtension) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    image = UIImage(data: data)
                } catch {}
            }
            widgetPostInfos.append(WidgetInfo(post: posts[index], image: image))
        }
        let entry = SimpleEntry(date: .now, posts: widgetPostInfos)
        return entry
    }

    func getTimeline(for configuration: CommunityIntentIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now + 60 * 60)))
        }
    }
}

struct CommunityWidget: Widget {
    let kind: String = "com.axlav.lemmios.recentCommunity"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: CommunityIntentIntent.self, provider: CommunityProvider()) { entry in
            postWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
        .configurationDisplayName("Latest Subscribed Widget")
        .description("This shows the hottest post(s) from your subscribed feed")
    }
}
