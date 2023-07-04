import CachedAsyncImage
import SwiftUI

struct PostPreviewComponent: View {
    @EnvironmentObject var apiModel: ApiModel
    @State private var offset: CGFloat = 0
    @State var bigArrow: Bool = false
    let maxLeadingOffset: CGFloat = 100
    let minTrailingOffset: CGFloat = -50

    let post: LemmyHttp.ApiPost
    let showCommunity: Bool
    let showUser: Bool

    var body: some View {
        VStack {
            let postModel = PostModel(post: post, apiModel: apiModel)
            NavigationLink(destination: PostView(postModel: postModel)) {
                VStack {
                    HStack {
                        Text(post.post.name)
                            .font(.title3)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    PostContentComponent(post: post, preview: true)
                    Divider()
                    PostActionsComponent(postModel: postModel, showCommunity: showCommunity, showUser: showUser, showButtons: true)
                }
                .contentShape(Rectangle())
                .addSwipe(leadingOptions: [SwipeOption(id: "upvote", image: "arrow.up", color: .orange), SwipeOption(id: "downvote", image: "arrow.down", color: .purple)], trailingOptions: []) { swiped in
                    if apiModel.selectedAccount == "" {
                        apiModel.getAuth()
                    } else {
                        switch swiped {
                        case "upvote":
                            postModel.vote(direction: true)
                        case "downvote":
                            postModel.vote(direction: false)
                        default:
                            break
                        }
                    }
                }
            }
            .accessibility(identifier: "post id: \(post.id)")
        }
    }
}

extension Date {
    func relativeDateAsString() -> String {
        let df = RelativeDateTimeFormatter()
        var dateString: String = df.localizedString(for: self, relativeTo: Date())
        dateString = dateString.replacingOccurrences(of: "months", with: "M")
            .replacingOccurrences(of: "month", with: "M")
            .replacingOccurrences(of: "weeks", with: "w")
            .replacingOccurrences(of: "week", with: "w")
            .replacingOccurrences(of: "days", with: "d")
            .replacingOccurrences(of: "day", with: "d")
            .replacingOccurrences(of: "minutes", with: "m")
            .replacingOccurrences(of: "minute", with: "m")
            .replacingOccurrences(of: "hours", with: "h")
            .replacingOccurrences(of: "hour", with: "h")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "ago", with: "")
        return dateString
    }
}

extension String {
    func date() -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .gmt
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter.date(from: "2023-07-04T02:11:43.086173")
    }
}
