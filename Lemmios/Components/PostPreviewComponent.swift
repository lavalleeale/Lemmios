import SwiftUI
import SwiftUIKit
import LinkPreview

struct PostPreviewComponent: View {
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @ObservedObject var postModel: PostModel
    @State private var offset: CGFloat = 0
    @State var showingReply = false

    let showCommunity: Bool
    let showUser: Bool
    let urlStyle: LinkPreviewType

    init(post: LemmyHttp.ApiPost, showCommunity: Bool, showUser: Bool, urlStyle: LinkPreviewType = .auto) {
        self.urlStyle = urlStyle
        self.postModel = PostModel(post: post)
        self.showCommunity = showCommunity
        self.showUser = showUser
    }

    var body: some View {
        VStack {
            Button {
                navModel.path.append(postModel)
            } label: {
                VStack {
                    HStack {
                        Text(postModel.post.name)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if postModel.post.nsfw {
                            NSFWBadgeComponent()
                        }
                        Spacer()
                    }
                    PostContentComponent(post: postModel, preview: true, previewType: urlStyle)
                    PostActionsComponent(postModel: postModel, showCommunity: showCommunity, showUser: showUser, collapsedButtons: true)
                }
                .contentShape(Rectangle())
                .padding()
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
}
