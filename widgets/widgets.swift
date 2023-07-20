import Combine
import LemmyApi
import SimpleKeychain
import SwiftUI
import WidgetKit

struct SimpleEntry: TimelineEntry {
    var date: Date
    let posts: [WidgetInfo]
}

struct WidgetInfo: Identifiable {
    var id: Int {
        post.id
    }

    let post: LemmyApi.ApiPost
    let image: UIImage?
}

struct postWidgetView: View {
    var entry: RecentProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
            switch widgetFamily {
            case .systemMedium:
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        PostIndex(posts: entry.posts, index: 0)
                        PostIndex(posts: entry.posts, index: 1)
                    }
                }
            case .systemLarge:
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        PostIndex(posts: entry.posts, index: 0)
                        PostIndex(posts: entry.posts, index: 1)
                    }
                    GridRow {
                        PostIndex(posts: entry.posts, index: 2)
                        PostIndex(posts: entry.posts, index: 3)
                    }
                }
            default:
                PostIndex(posts: entry.posts, index: 0)
            }
    }
}

struct PostIndex: View {
    let posts: [WidgetInfo]
    let index: Int
    var body: some View {
        if let post = posts[safe: index] {
            PostComponent(post: post.post, image: post.image)
        } else {
            ZStack {
                Rectangle()
                    .fill(gradient)
                Text("No Posts Found")
            }
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func getTargetNum(_ family: WidgetFamily) -> Int {
    switch family {
    case .systemMedium:
        return 1
    case .systemLarge:
        return 3
    default:
        return 0
    }
}

// MARK: Copied

let imageExtensions = ["png", "jpeg", "jpg", "heic", "bmp", "webp"]

func formatNum(num: Int) -> String {
    num < 1000 ? String(num) : String("\(round((Double(num) / 1000) * 10) / 10)K")
}

struct StoredAccount: Codable, Identifiable, Equatable {
    static func == (lhs: StoredAccount, rhs: LemmyApi.ApiUserData) -> Bool {
        return rhs.actor_id.pathComponents.last! == lhs.username && rhs.actor_id.host() == lhs.instance
    }

    static func == (lhs: LemmyApi.ApiUserData, rhs: StoredAccount) -> Bool {
        return rhs == lhs
    }

    static func != (lhs: StoredAccount, rhs: LemmyApi.ApiUserData) -> Bool {
        return !(lhs == rhs)
    }

    static func != (lhs: LemmyApi.ApiUserData, rhs: StoredAccount) -> Bool {
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
