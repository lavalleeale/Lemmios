import LemmyApi
import MarkdownUI
import SwiftUI
import SwiftUIKit

let colors = [Color.green, Color.red, Color.orange, Color.yellow]

struct CommentComponent: View {
    @Environment(\.redactionReasons) private var reasons
    @ObservedObject var commentModel: CommentModel
    @State var collapsed = false
    @State var preview = false
    @State var showingReply = false
    @State var showingEdit = false
    @State var showingReport = false
    @State var reportReason = ""
    var replyInfo: LemmyApi.ReplyInfo?
    @EnvironmentObject var post: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var postModel: PostModel
    @AppStorage("commentImages") var commentImages = true

    let depth: Int

    var read: (() -> Void)?

    let collapseParent: (() -> Void)?

    var share: ((Int) -> Void)?

    var menuButtons: some View {
        Group {
            if let account = apiModel.selectedAccount, account == commentModel.comment.creator {
                PostButton(label: "Edit", image: "pencil") {
                    showingEdit = true
                }
                PostButton(label: commentModel.comment.comment.deleted ? "Restore" : "Delete", image: commentModel.comment.comment.deleted ? "trash.slash" : "trash") {
                    commentModel.delete(apiModel: apiModel)
                }
            } else {
                PostButton(label: "Report", image: "flag") {
                    showingReport = true
                }
            }
            PostButton(label: "Share as Image", image: "square.and.arrow.up", needsAuth: false) {
                share?(commentModel.comment.id)
            }
            ShareLink(item: commentModel.comment.comment.ap_id) {
                Label {
                    Text("Share")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .padding(.all, 10)
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        UserLink(user: commentModel.comment.creator)
                            .accessibility(identifier: "\(commentModel.comment.creator.name) user button")
                            .foregroundColor(commentModel.comment.creator.id == commentModel.comment.post.creator_id ? Color.blue : Color.primary)
                        ScoreComponent(votableModel: commentModel)
                        Spacer()
                        if !reasons.contains(.screenshot) {
                            Menu { menuButtons } label: {
                                Label {
                                    Text("Comment Options")
                                } icon: {
                                    Image(systemName: "ellipsis")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }
                                .labelStyle(.iconOnly)
                            }
                            .foregroundStyle(.secondary)
                            .highPriorityGesture(TapGesture())
                        }
                        Text(commentModel.comment.counts.published.relativeDateAsString())
                            .foregroundStyle(.secondary)
                        if replyInfo != nil {
                            Image(systemName: replyInfo!.read ? "envelope.open" : "envelope.badge")
                                .symbolRenderingMode(.multicolor)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .redacted(reason: .privacy)
                    if !collapsed {
                        if commentModel.comment.comment.deleted {
                            Text("deleted by creator")
                                .italic()
                        } else if commentModel.comment.comment.removed {
                            Text("removed by mod")
                                .italic()
                        } else {
                            Markdown(processMarkdown(input: commentModel.comment.comment.content, stripImages: !commentImages), baseURL: URL(string: apiModel.url)!)
                        }
                    }
                }
                .contentShape(Rectangle())
                .commentDepthIndicator(depth: depth)
                .padding(.top, 10)
                Spacer()
                    .frame(height: 10)
            }
            .onTapGesture {
                if preview {
                    if let replyInfo = replyInfo, replyInfo.read == false {
                        commentModel.read(replyInfo: replyInfo, apiModel: apiModel) {
                            read!()
                        }
                    }
                    navModel.path.append(PostModel(post: commentModel.comment.post, comment: commentModel.comment))
                } else {
                    withAnimation {
                        collapsed.toggle()
                    }
                }
            }
            .padding(.horizontal)
            .if(!reasons.contains(.screenshot)) { view in
                view
                    .addSwipe(leadingOptions: [
                        SwipeOption(id: "upvote", image: "arrow.up", color: .orange),
                        SwipeOption(id: "downvote", image: "arrow.down", color: .purple)
                    ],
                    trailingOptions: [
                        replyInfo != nil ? SwipeOption(id: "read", image: replyInfo!.read ? "envelope.badge" : "envelope.open", color: Color(hex: "3880EF")!) : SwipeOption(id: "collapse", image: "arrow.up.to.line", color: Color(hex: "3880EF")!),
                        SwipeOption(id: "reply", image: "arrowshape.turn.up.left", color: .blue)
                    ]) { swiped in
                        switch swiped {
                        case "upvote":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                commentModel.vote(direction: true, apiModel: apiModel)
                            }
                        case "downvote":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                commentModel.vote(direction: false, apiModel: apiModel)
                            }
                        case "reply":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                showingReply = true
                            }
                        case "read":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                commentModel.read(replyInfo: replyInfo!, apiModel: apiModel) {
                                    read!()
                                }
                            }
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
            .contextMenu { menuButtons }
            .overlay {
                Color.gray.opacity(!preview && postModel.selectedComment?.id == commentModel.comment.id ? 0.3 : 0)
                    .allowsHitTesting(false)
            }
            if commentModel.comment.counts.child_count != 0 && commentModel.children.isEmpty && !preview {
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
            LazyVStack(spacing: 0) {
                let directChildren = commentModel.children.filter { isCommentParent(parentId: commentModel.comment.id, possibleChild: $0) }
                ForEach(directChildren) { comment in
                    Divider()
                        .padding(.leading, CGFloat(depth + 1) * 10)
                    CommentComponent(commentModel: CommentModel(comment: comment, children: commentModel.children.filter { $0.comment.path.contains("\(comment.id).") }), depth: depth + 1, collapseParent: {
                        if collapseParent != nil {
                            collapseParent!()
                        } else {
                            self.collapsed = true
                        }
                    }, share: share)
                }
            }
            .allowsHitTesting(!collapsed)
            .frame(maxHeight: commentModel.children.isEmpty || collapsed ? 0 : .infinity)
            .clipped()
        }
        .alert("Report", isPresented: $showingReport) {
            TextField("Reason", text: $reportReason)
            Button("OK") {
                commentModel.report(reason: reportReason, apiModel: apiModel)
                showingReport = false
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet(title: "Add Comment") { commentBody in
                commentModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
        .sheet(isPresented: $showingEdit) {
            CommentSheet(commentBody: commentModel.comment.comment.content, title: "Edit Comment") { commentBody in
                commentModel.edit(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
    }
}

public extension RedactionReasons {
    static let screenshot = RedactionReasons(rawValue: 1 << 10)
}
