import CachedAsyncImage
import LemmyApi
import SwiftUI

struct UserLink: View {
    let user: LemmyApi.ApiUserData
    var showPlaceholder = false
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @Environment(\.showUsernames) var showUsernames: Bool

    var body: some View {
        let model = UserModel(user: user)
        Button {} label: {
            ShowFromComponent(item: user, showPlaceholder: showPlaceholder, show: showUsernames)
        }
        .highPriorityGesture(TapGesture().onEnded {
            navModel.path.append(model)
        })
        .buttonStyle(.plain)
        .contextMenu {
            ShareLink("Share", item: user.actor_id)
        } preview: {
            UserView(userModel: model)
                .environmentObject(apiModel)
        }
    }
}

struct CommunityLink<Prefix: View, Suffix: View>: View {
    let community: LemmyApi.ApiCommunityData
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    var showPlaceholder = false
    @ViewBuilder var prefix: Prefix
    @ViewBuilder var suffix: Suffix
    @Environment(\.showCommunities) var showCommunities: Bool

    var body: some View {
        let model = PostsModel(path: "\(community.name)\(community.local ? "" : "@\(community.actor_id.host()!)")")
        Button {} label: {
            HStack {
                prefix
                ShowFromComponent(item: community, showPlaceholder: showPlaceholder, show: showCommunities)
                suffix
            }
        }
        .highPriorityGesture(TapGesture().onEnded {
            navModel.path.append(model)
        })
        .buttonStyle(.plain)
        .contextMenu {
            ShareLink("Share", item: community.actor_id)
        } preview: {
            PostsView(postsModel: model)
                .environmentObject(apiModel)
        }
    }
}

private struct ShowFromComponent<T: WithNameHost>: View {
    @EnvironmentObject var apiModel: ApiModel
    @State var item: T
    var showPlaceholder = false
    var show: Bool
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("showCommuntiies") var showCommuntiies = true
    @Environment(\.redactionReasons) private var reasons

    var body: some View {
        HStack {
            if let icon = item.icon {
                CachedAsyncImage(url: icon, urlCache: .imageCache, content: { image in
                    image
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 12, height: 12)
                }, placeholder: {
                    ProgressView()
                        .hidden(if: reasons.contains(.screenshot))
                })
            } else if showPlaceholder {
                Circle()
                    .fill(selectedTheme.secondaryColor)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Text(item.name.first!.uppercased())
                    }
            }
            if item.local || !showCommuntiies {
                Text(item.name)
                    .lineLimit(1)
            } else {
                let itemHost = item.actor_id.host()!
                Text("\(item.name)\(Text("@\(itemHost)").foregroundColor(.secondary))")
                    .lineLimit(1)
            }
        }
        .if(!show) { view in
            view.redacted(reason: .placeholder)
        }
    }
}
