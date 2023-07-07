import MarkdownUI
import SwiftUI
import SwiftUIKit

let colors = [Color.green, Color.red, Color.orange, Color.yellow]

struct CommentComponent: View {
    @ObservedObject var commentModel: CommentModel
    @State var collapsed = false
    @State var preview = false
    @State var showingReply = false
    @EnvironmentObject var post: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var postModel: PostModel

    let depth: Int

    let collapseParent: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Button(commentModel.comment.creator.name) {}
                                .highPriorityGesture(TapGesture().onEnded {
                                    navModel.path.append(UserModel(user: commentModel.comment.creator))
                                })
                                .accessibility(identifier: "\(commentModel.comment.creator.name) user button")
                                .foregroundColor(commentModel.comment.creator.id == commentModel.comment.post.creator_id ? Color.blue : Color.primary)
                            ScoreComponent(votableModel: commentModel)
                            Spacer()
                            Text(commentModel.comment.counts.published.relativeDateAsString())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        if !collapsed {
                            Markdown(processMarkdown(input: commentModel.comment.comment.content, comment: true), baseURL: URL(string: apiModel.url)!)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .commentDepthIndicator(depth: depth)
                .padding(.top, 10)
                Spacer()
                    .frame(height: 10)
            }
            .onTapGesture {
                if preview {
                    navModel.path.append(PostModel(post: commentModel.comment.post, comment: commentModel.comment))
                } else {
                    withAnimation {
                        collapsed.toggle()
                    }
                }
            }
            .addSwipe(leadingOptions: [SwipeOption(id: "upvote", image: "arrow.up", color: .orange), SwipeOption(id: "downvote", image: "arrow.down", color: .purple)], trailingOptions: [SwipeOption(id: "collapse", image: "arrow.up.to.line", color: Color(hex: "3880EF")!), SwipeOption(id: "reply", image: "arrowshape.turn.up.left", color: .blue)]) { swiped in
                if apiModel.selectedAccount == "" {
                    apiModel.getAuth()
                } else {
                    switch swiped {
                    case "upvote":
                        commentModel.vote(direction: true, apiModel: apiModel)
                    case "downvote":
                        commentModel.vote(direction: false, apiModel: apiModel)
                    case "reply":
                        showingReply = true
                        return
                    case "collapse":
                        withAnimation {
                            if collapseParent != nil {
                                collapseParent!()
                            } else {
                                self.collapsed = true
                            }
                        }
                        return
                    default:
                        break
                    }
                }
            }
            if commentModel.comment.counts.child_count != 0 && commentModel.children.count == 0 && !preview {
                Divider()
                    .padding(.leading, CGFloat(depth + 1) * 10)
                HStack {
                    Button {
                        commentModel.fetchComments(apiModel: apiModel, postModel: postModel)
                    } label: {
                        if case .loading = commentModel.pageStatus {
                            ProgressView()
                        } else {
                            Text("Show \(commentModel.comment.counts.child_count) More")
                        }
                    }
                    .frame(height: 30, alignment: .leading)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .commentDepthIndicator(depth: depth + 1)
            }
            VStack(spacing: 0) {
                let directChildren = commentModel.children.filter { isCommentParent(parentId: commentModel.comment.id, possibleChild: $0) }
                ForEach(directChildren) { comment in
                    Divider()
                        .padding(.leading, CGFloat(depth + 1) * 10)
                    CommentComponent(commentModel: CommentModel(comment: comment, children: commentModel.children.filter { $0.comment.path.contains("\(comment.id).") }), depth: depth + 1) {
                        if collapseParent != nil {
                            collapseParent!()
                        } else {
                            self.collapsed = true
                        }
                    }
                }
            }
            .allowsHitTesting(!collapsed)
            .frame(maxHeight: commentModel.children.count == 0 || collapsed ? 0 : .infinity)
            .clipped()
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet { commentBody in
                commentModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
    }
}
