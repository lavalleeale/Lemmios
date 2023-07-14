import LinkPreview
import SwiftUI
import SwiftUIKit

struct PostPreviewComponent: View {
    @AppStorage("compact") var compact = false
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @ObservedObject var postModel: PostModel
    @State private var offset: CGFloat = 0
    @State var showingReply = false

    let showCommunity: Bool
    let showUser: Bool

    init(post: LemmyHttp.ApiPost, showCommunity: Bool, showUser: Bool) {
        self.postModel = PostModel(post: post)
        self.showCommunity = showCommunity
        self.showUser = showUser
    }

    var body: some View {
        Button {
            navModel.path.append(postModel)
        } label: {
            HStack {
                if compact {
                    PostContentComponent(post: postModel, preview: true)
                        .frame(maxWidth: 50, maxHeight: 50, alignment: .center)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary))
                }
                VStack {
                    HStack {
                        Text(postModel.post.name)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if postModel.post.featured_community {
                            Label {
                                Text("Community Pin")
                            } icon: {
                                Image(systemName: "pin")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .rotationEffect(.degrees(45))
                            }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.green)
                        }
                        if postModel.post.featured_local {
                            Label {
                                Text("Local Pin")
                            } icon: {
                                Image(systemName: "pin")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .rotationEffect(.degrees(45))
                            }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.secondary)
                        }
                        if postModel.post.nsfw {
                            NSFWBadgeComponent()
                        }
                        Spacer()
                    }
                    if !compact {
                        PostContentComponent(post: postModel, preview: true)
                    }
                    PostActionsComponent(postModel: postModel, showCommunity: showCommunity, showUser: showUser, collapsedButtons: true, showArrows: !compact, preview: true)
                }
                if compact {
                    VStack {
                        ArrowsComponent(votableModel: postModel)
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(compact ? .horizontal : .all)
            .addSwipe(leadingOptions: [
                SwipeOption(id: "upvote", image: "arrow.up", color: .orange),
                SwipeOption(id: "downvote", image: "arrow.down", color: .purple)
            ], trailingOptions: [
                SwipeOption(id: "reply", image: "arrowshape.turn.up.left", color: .blue),
                SwipeOption(id: "save", image: postModel.saved ? "bookmark.slash" : "bookmark", color: .green)
            ], compressable: postModel.post.url == nil) { swiped in
                if apiModel.selectedAccount == nil {
                    apiModel.getAuth()
                } else {
                    switch swiped {
                    case "upvote":
                        postModel.vote(direction: true, apiModel: apiModel)
                        return
                    case "downvote":
                        postModel.vote(direction: false, apiModel: apiModel)
                        return
                    case "reply":
                        showingReply = true
                        return
                    case "save":
                        postModel.save(apiModel: apiModel)
                    default:
                        break
                    }
                }
            }
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet(title: "Add Comment") { commentBody in
                postModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
        .accessibility(identifier: "post id: \(postModel.post.id)")
    }
}
