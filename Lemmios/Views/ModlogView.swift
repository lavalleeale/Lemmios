import LemmyApi
import SwiftUI

struct ModlogView: View {
    private let df = RelativeDateTimeFormatter()
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var modlogModel: ModlogModel
    var body: some View {
        ColoredListComponent {
            let entries = modlogModel.logEntries.sorted { $0.date > $1.date }
            ForEach(entries, id: \.id) { entry in
                VStack(alignment: .leading) {
                    HStack {
                        if let mod = entry.moderator {
                            UserLink(user: mod)
                        }
                        Spacer()
                        Text(entry.date.relativeDateAsString())
                            .foregroundStyle(.secondary)
                    }
                    if let entry = entry as? LemmyApi.ModRemovePostView {
                        Text("\(entry.mod_remove_post.removed ? "Removed" : "Restored") post")
                        if apiModel.moderates?.contains(where: { $0.id == entry.community.id }) == true {
                            NavigationLink(entry.post.name, value: PostModel(post: entry.post, comment: nil))
                                .foregroundColor(.green)
                        } else {
                            Text(entry.post.name)
                                .foregroundColor(.green)
                        }
                    } else if let entry = entry as? LemmyApi.ModRemoveCommentView {
                        Text("\(entry.mod_remove_comment.removed ? "Removed" : "Restored") comment")
                        if apiModel.moderates?.contains(where: { $0.id == entry.community.id }) == true {
                            NavigationLink(entry.comment.content, value: PostModel(post: entry.post, comment: entry.comment))
                                .foregroundColor(.green)
                        } else {
                            Text(entry.post.name)
                                .foregroundColor(.green)
                        }
                    } else if let entry = entry as? LemmyApi.ModBanFromCommunityView {
                        Text("\(entry.mod_ban_from_community.banned ? "Banned" : "Unbanned") user")
                        NavigationLink(value: UserModel(user: entry.banned_person)) {
                            ShowFromComponent(item: entry.banned_person, show: true)
                                .foregroundStyle(.blue)
                        }
                        if let reason = entry.mod_ban_from_community.reason {
                            Text("Reason: \(reason)")
                        }
                        if let expires = entry.mod_ban_from_community.expires {
                            Text("Expires: \(df.localizedString(for: expires, relativeTo: Date()))")
                        }
                    }
                }
                .onAppear {
                    if entry.id == entries.last?.id {
                        modlogModel.fetchLog(apiModel: apiModel)
                    }
                }
            }
        }
        .onAppear {
            modlogModel.fetchLog(apiModel: apiModel)
        }
    }
}
