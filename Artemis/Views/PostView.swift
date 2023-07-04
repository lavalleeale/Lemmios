import SwiftUI
import WebKit

struct PostView: View {
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @State var collapsed: Bool = false
    @State var parentContent: String? = nil

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                if !collapsed {
                    PostContentComponent(post: postModel.post, preview: false)
                }
                Text(postModel.post.post.name)
                    .font(.title3)
                    .lineLimit(collapsed ? 1 : .max)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                print(1)
                withAnimation {
                    collapsed.toggle()
                }
            }
            PostActionsComponent(postModel: postModel, showCommunity: true, showUser: true, showButtons: false)
            Divider()
            ArrowsComponent(votableModel: postModel)
            Divider()
                .onAppear {
                    if self.postModel.comments.count == 0 {
                        self.postModel.fetchComments()
                    }
                }
//            if case .loading = postModel.pageStatus && postModel.comments.count == 0 {
//                ProgressView()
//            }
            ForEach(postModel.comments.filter { isCommentParent(parentId: "0", possibleChild: $0) }) { comment in
                CommentComponent(commentModel: CommentModel(comment: comment, children: postModel.comments.filter { $0.comment.path.contains("\(comment.id).") }, apiModel: apiModel))
            }
            if case .failed = postModel.pageStatus {
                HStack {
                    Text("Lemmy Request Failed, ")
                    Button("refresh?") {
                        postModel.refresh()
                    }
                }
            }
        }
        .refreshable {
            postModel.refresh()
        }
        .navigationBarTitle(postModel.post.post.name, displayMode: .inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                SortSelectorComponent(function: postModel.changeSort, currentSort: $postModel.sort)
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
