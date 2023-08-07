import AlertToast
import LemmyApi
import SwiftUI
import WebKit

struct PostView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @StateObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var collapsed: Bool = false
    @State var parentContent: String? = nil
    @State var showingPost = false
    @State var sharingComments: [LemmyApi.CommentView]?

    func share(commentId: Int) {
        let sharingComment = postModel.comments.first { $0.id == commentId }
        self.sharingComments = postModel.comments.filter { comment in sharingComment?.comment.path.components(separatedBy: ".").contains(String(comment.id)) == true }
    }

    var body: some View {
        ZStack {
            let minDepth = postModel.comments.min { $0.comment.path.split(separator: ".").count < $1.comment.path.split(separator: ".").count }?.comment.path.split(separator: ".").count
            let topLevels = postModel.comments.filter { $0.comment.path.split(separator: ".").count == minDepth }
            if let sharingComments = sharingComments {
                PostSharePreview(postModel: postModel, isPresented: Binding(get: { self.sharingComments != nil }, set: { _ in self.sharingComments = nil }), comments: sharingComments)
            }
            Rectangle()
                .fill(selectedTheme.primaryColor)
            ScrollViewReader { value in
                ScrollView {
                    EmptyView()
                        .id("top")
                    // Hack to make sure appear methods are called
                    LazyVStack {
                        Text(postModel.post.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bold()
                            .lineLimit(collapsed ? 1 : .max)
                            .multilineTextAlignment(.leading)
                        if !collapsed {
                            Spacer()
                                .frame(height: 30)
                            PostContentComponent(post: postModel, preview: false)
                                .onAppear {
                                    withAnimation {
                                        showingPost = true
                                    }
                                }
                                .onDisappear {
                                    withAnimation {
                                        showingPost = false
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onAppear {
                        postModel.getPostDetails(apiModel: apiModel)
                        if !apiModel.seen.contains(postModel.post.id) {
                            apiModel.seen.append(postModel.post.id)
                        }
                    }
                    .padding(.all, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            collapsed.toggle()
                            value.scrollTo("top")
                        }
                    }
                    if postModel.creator != nil {
                        PostActionsComponent(postModel: postModel, showCommunity: true, showUser: true, collapsedButtons: false, rowButtons: true, preview: false)
                            .onAppear {
                                if postModel.comments.count == 0 {
                                    postModel.fetchComments(apiModel: apiModel)
                                }
                            }
                    }
                    LazyVStack(spacing: 0) {
                        if let minDepth = minDepth, minDepth > 2 {
                            HStack {
                                Image(systemName: "chevron.up")
                                Button("Load parent comment...") {
                                    postModel.getParent(currentDepth: minDepth, apiModel: apiModel)
                                }
                                Spacer()
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding()
                            Divider()
                        }
                        ForEach(topLevels) { comment in
                            let model = CommentModel(comment: comment, children: postModel.comments.filter { $0.comment.path.contains("\(comment.id).") })
                            CommentComponent(parent: model, commentModel: model, depth: 0, collapseParent: nil, share: share)
                                .id(comment.id)
                            Divider()
                        }
                        .environmentObject(postModel)
                    }
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
                    }
                    Spacer()
                        .frame(height: 100)
                }
                .overlay(alignment: .bottomTrailing) {
                    if showingPost, postModel.selectedCommentPath == nil {
                        Button {
                            withAnimation {
                                value.scrollTo(topLevels.first?.id, anchor: .top)
                            }
                        } label: {
                            Label("Scroll to Comments", systemImage: "chevron.down")
                                .labelStyle(.iconOnly)
                        }
                        .foregroundStyle(.primary)
                        .padding(20)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .padding([.bottom, .trailing], 5)
                    }
                }
            }
            .refreshable {
                postModel.refresh(apiModel: apiModel)
            }
            .toast(isPresenting: .constant(postModel.selectedCommentPath != nil && postModel.community != nil), duration: .infinity) {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: "View All Comments", subTitle: "This is a single comment thread from the post.", style: .style(backgroundColor: .blue, titleColor: .primary, subTitleColor: .secondary))
            } onTap: {
                navModel.path.append(PostModel(post: LemmyApi.PostView(post: postModel.post, creator: postModel.creator!, community: postModel.community!, counts: postModel.counts!, my_vote: postModel.likes, saved: postModel.saved, creator_banned_from_community: postModel.creator_banned_from_community)))
            }
            .navigationBarTitle(postModel.counts?.comments == nil ? "Post" : "\(formatNum(num: postModel.counts!.comments)) Comments", displayMode: .inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortSelectorComponent(currentSort: $postModel.sort) { sort in
                        postModel.changeSort(sort: sort, apiModel: apiModel)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    PostButtons(postModel: postModel, showViewComments: false, menu: true, showAll: true)
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
}
