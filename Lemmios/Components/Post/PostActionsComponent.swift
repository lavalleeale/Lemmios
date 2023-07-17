import SwiftUI
import SwiftUIKit

struct PostActionsComponent: View {
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @AppStorage("compact") var compact = false
    
    let showCommunity: Bool
    let showUser: Bool
    let collapsedButtons: Bool
    let rowButtons: Bool
    var showInfo = true
    var showArrows = true
    var image = false
    let preview: Bool
    
    var body: some View {
        VStack {
            HStack {
                if showInfo {
                    DynamicStack(vertical: !compact || !preview) {
                        HStack {
                            if showCommunity {
                                CommunityLink(community: postModel.community!, prefix: {}, suffix: {})
                            }
                            if showUser {
                                UserLink(user: postModel.creator!)
                            }
                        }
                        HStack(spacing: compact && preview ? 0 : nil) {
                            ScoreComponent(votableModel: postModel, preview: preview)
                            Group {
                                HStack(spacing: compact && preview ? 0 : 3) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .scaleEffect(compact && preview ? 0.5 : 0.8)
                                    Text(formatNum(num: postModel.counts!.comments))
                                        .font(compact && preview ? .caption : nil)
                                }
                                HStack(spacing: compact && preview ? 0 : 3) {
                                    Image(systemName: "clock")
                                        .scaleEffect(compact && preview ? 0.5 : 0.8)
                                    Text(postModel.counts!.published.relativeDateAsString())
                                        .font(compact && preview ? .caption : nil)
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                if !compact || !preview {
                    Spacer()
                }
                if collapsedButtons {
                    HStack {
                        PostButtons(postModel: postModel, showViewComments: !showInfo, menu: true, showAll: true, image: image)
                            .foregroundStyle(.secondary)
                        if showArrows {
                            ArrowsComponent(votableModel: postModel)
                        }
                    }
                }
                if compact && preview {
                    Spacer()
                }
            }
            if rowButtons {
                Divider()
                HStack {
                    Group {
                        if showArrows {
                            ArrowsComponent(votableModel: postModel)
                        }
                        PostButtons(postModel: postModel, showViewComments: !showInfo, menu: false, showAll: false, image: image)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Divider()
            }
        }
    }
}

struct DynamicStack<Content: View>: View {
    let vertical: Bool
    @ViewBuilder var content: Content
    var body: some View {
        if vertical {
            VStack(alignment: .leading) {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}

struct PostButtons: View {
    @ObservedObject var postModel: PostModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var apiModel: ApiModel
    @State var showingReply = false
    @State var showingReport = false
    @State var reportReason = ""
    @State var showingShare = false
    @State var showingEdit = false
    
    var showViewComments: Bool
    var menu: Bool
    var showAll: Bool
    var image = false
    
    var buttons: some View {
        Group {
            if showViewComments {
                PostButton(label: "Comments", image: "bubble.left.and.bubble.right", needsAuth: false) {
                    dismiss()
                    navModel.path.append(postModel)
                }
            }
            PostButton(label: postModel.saved ? "Unsave" : "Save", image: postModel.saved ? "bookmark.fill" : "bookmark") {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                postModel.save(apiModel: apiModel)
            }
            PostButton(label: "Reply", image: "arrowshape.turn.up.left") {
                showingReply = true
            }
            if showAll {
                if let account = apiModel.selectedAccount, let user = postModel.creator, account == user {
                    PostButton(label: postModel.post.deleted ? "Restore" : "Delete", image: postModel.post.deleted ? "trash.slash" : "trash") {
                        postModel.delete(apiModel: apiModel)
                    }
                    PostButton(label: "Edit", image: "pencil") {
                        showingEdit = true
                    }
                } else {
                    PostButton(label: "Report", image: "flag") {
                        showingReport = true
                    }
                }
                Button { showingShare = true } label: {
                    Label {
                        Text("Share as Image")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(.all, 10)
                    }
                }
            }
            Button {
                if image {
                    URLSession.shared.dataTask(with: postModel.post.url!) { data, _, _ in
                        guard let data = data,
                              let image = UIImage(data: data)
                        else { return }
                        
                        DispatchQueue.main.async {
                            alwaysShare(item: ItemDetailSource(name: postModel.post.name, image: image))
                        }
                    }.resume()
                } else {
                    alwaysShare(item: postModel.post.ap_id)
                }
            } label: {
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
            .foregroundStyle(.secondary)
        }
    }
    
    var body: some View {
        Group {
            if menu {
                Menu {
                    buttons
                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            } else {
                buttons
                    .labelStyle(.iconOnly)
            }
        }
        .overlay {
            PostSharePreview(postModel: postModel, isPresented: $showingShare, comments: [])
        }
        .sheet(isPresented: $showingEdit) {
            PostCreateComponent(title: postModel.post.name, postData: postModel.post.body ?? "", postUrl: postModel.post.url?.absoluteString ?? "", dataModel: postModel)
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet(title: "Add Comment") { commentBody in
                postModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
        .alert("Report", isPresented: $showingReport) {
            TextField("Reason", text: $reportReason)
            Button("OK") {
                postModel.report(reason: reportReason, apiModel: apiModel)
                showingReport = false
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct PostButton: View {
    @EnvironmentObject var apiModel: ApiModel
    
    let label: String
    let image: String
    var needsAuth = true
    let action: () -> Void
    
    var body: some View {
        Button {
            if needsAuth && apiModel.selectedAccount == nil {
                apiModel.getAuth()
            } else {
                action()
            }
        } label: {
            Label {
                Text(label)
            } icon: {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(.all, 10)
            }
        }
        .foregroundStyle(.secondary)
    }
}
