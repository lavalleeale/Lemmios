import AlertToast
import SwiftUI
import WebKit

struct PostView: View {
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var collapsed: Bool = false
    @State var parentContent: String? = nil

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Text(postModel.post.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title2)
                    .lineLimit(collapsed ? 1 : .max)
                    .multilineTextAlignment(.leading)
                if !collapsed {
                    Spacer()
                        .frame(height: 30)
                    PostContentComponent(post: postModel.post, preview: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .onAppear {
                postModel.getPostDetails(apiModel: apiModel)
            }
            .padding(.all, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    collapsed.toggle()
                }
            }
            LazyVStack(spacing: 0) {
                if postModel.creator != nil {
                    PostActionsComponent(postModel: postModel, showCommunity: true, showUser: true, collapsedButtons: false)
                        .onAppear {
                            if postModel.comments.count == (postModel.commentId == nil ? 0 : 1) {
                                postModel.fetchComments(apiModel: apiModel)
                            }
                        }
                }
                let topLevels = postModel.comments.filter { $0.id == postModel.commentId || isCommentParent(parentId: 0, possibleChild: $0) }
                ForEach(topLevels) { comment in
                    CommentComponent(commentModel: CommentModel(comment: comment, children: postModel.comments.filter { $0.comment.path.contains("\(comment.id).") }), depth: 0, collapseParent: nil)
                    Divider()
                }
            }
            .environmentObject(postModel)
            if case .failed = postModel.pageStatus {
                HStack {
                    Text("Lemmy Request Failed, ")
                    Button("refresh?") {
                        postModel.refresh(apiModel: apiModel)
                    }
                }
            } else if case .done = postModel.pageStatus {
                HStack {
                    Text("Last Comment Found ):")
                }
            } else if case .loading = postModel.pageStatus {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .refreshable {
            postModel.refresh(apiModel: apiModel)
        }
        .toast(isPresenting: .constant(postModel.commentId != nil && postModel.community != nil), duration: .infinity) {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: "View All Comments", subTitle: "This is a single comment thread from the post.", style: .style(backgroundColor: .blue, titleColor: .primary, subTitleColor: .secondary))
        } onTap: {
            navModel.path.append(PostModel(post: LemmyHttp.ApiPost(post: postModel.post, creator: postModel.creator!, community: postModel.community!, counts: postModel.counts!, my_vote: postModel.likes, saved: postModel.saved)))
        }
        .navigationBarTitle(postModel.counts?.comments == nil ? "Post" : "\(formatNum(num: postModel.counts!.comments)) Comments", displayMode: .inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                SortSelectorComponent(currentSort: $postModel.sort) { sort in
                    postModel.changeSort(sort: sort, apiModel: apiModel)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if self.parentContent != nil {
                    Text("Single Comment Thread")
                        .padding()
                        .frame(width: UIScreen.main.bounds.width / 2)
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color.blue))
                } else {
                    EmptyView()
                }
            }
        })
    }
}
