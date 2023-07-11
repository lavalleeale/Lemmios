import SimpleHaptics
import SwiftUI
import SwiftUIKit

struct PostActionsComponent: View {
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    
    let showCommunity: Bool
    let showUser: Bool
    let collapsedButtons: Bool
    var showInfo = true
    
    var body: some View {
        VStack {
            HStack {
                if showInfo {
                    VStack(alignment: .leading) {
                        HStack {
                            if showCommunity {
                                ShowFromComponent(item: postModel.community!)
                                    .highPriorityGesture(TapGesture().onEnded {
                                        if postModel.community!.local {
                                            navModel.path.append(PostsModel(path: postModel.community!.name))
                                        } else {
                                            let communityHost = postModel.community!.actor_id.host()!
                                            navModel.path.append(PostsModel(path: "\(postModel.community!.name)@\(communityHost)"))
                                        }
                                    })
                            }
                            if showUser {
                                HStack(spacing: 0) {
                                    ShowFromComponent(item: postModel.creator!)
                                }
                                .highPriorityGesture(TapGesture().onEnded {
                                    navModel.path.append(UserModel(user: postModel.creator!))
                                })
                            }
                        }
                        HStack {
                            ScoreComponent(votableModel: postModel)
                            HStack {
                                HStack(spacing: 3) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                    Text(formatNum(num: postModel.counts!.comments))
                                }
                                HStack(spacing: 3) {
                                    Image(systemName: "clock")
                                    Text(postModel.counts!.published.relativeDateAsString())
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                if collapsedButtons {
                    HStack {
                        PostButtons(postModel: postModel, showViewComments: !showInfo, menu: true)
                            .foregroundStyle(.secondary)
                        ArrowsComponent(votableModel: postModel)
                    }
                }
            }
            if !collapsedButtons {
                Divider()
                HStack {
                    Group {
                        ArrowsComponent(votableModel: postModel)
                        PostButtons(postModel: postModel, showViewComments: !showInfo, menu: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Divider()
            }
        }
    }
}

struct PostButtons: View {
    @ObservedObject var postModel: PostModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @EnvironmentObject var apiModel: ApiModel
    @State var showingReply = false
    @State var showingReport = false
    @State var reportReason = ""
    
    var showViewComments: Bool
    var menu: Bool
    
    var buttons: some View {
        Group {
            if showViewComments {
                PostButton(label: "Comments", image: "bubble.left.and.bubble.right") {
                    dismiss()
                    navModel.path.append(postModel)
                }
            }
            if menu {
                PostButton(label: "Report", image: "flag") {
                    showingReport = true
                }
            }
            PostButton(label: postModel.saved ? "Unsave" : "Save", image: postModel.saved ? "bookmark.slash" : "bookmark") {
                try? haptics.fire()
                postModel.save(apiModel: apiModel)
            }
            PostButton(label: "Reply", image: "arrowshape.turn.up.left") {
                showingReply = true
            }
            PostButton(label: "Share", image: "square.and.arrow.up") {
                showShareSheet(url: postModel.post.ap_id)
            }
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
    let action: () -> Void
    
    var body: some View {
        Button {
            if apiModel.selectedAccount == "" {
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
