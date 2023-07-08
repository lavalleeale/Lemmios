import SimpleHaptics
import SwiftUI
import SwiftUIKit

struct PostActionsComponent: View {
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @Environment(\.dismiss) private var dismiss
    @State var showingReply = false
    
    let showCommunity: Bool
    let showUser: Bool
    let collapsedButtons: Bool
    var showInfo = true
    
    var body: some View {
        VStack {
            HStack {
                if showInfo {
                    let communityHost = postModel.community!.actor_id.host()!
                    let apiHost = URL(string: apiModel.url)!.host()!
                    VStack(alignment: .leading) {
                        HStack {
                            if showCommunity {
                                ShowFromComponent(item: postModel.community!)
                                    .highPriorityGesture(TapGesture().onEnded {
                                        if communityHost == apiHost {
                                            navModel.path.append(PostsModel(path: postModel.community!.name))
                                        } else {
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
                                Image(systemName: "bubble.left.and.bubble.right")
                                Text(formatNum(num: postModel.counts!.comments))
                                Image(systemName: "clock")
                                Text(postModel.counts!.published.relativeDateAsString())
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                if collapsedButtons {
                    Menu {
                        CollapsedButtons
                    } label: {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(.all, 10)
                    }
                    .foregroundStyle(.secondary)
                    ArrowsComponent(votableModel: postModel)
                }
            }
            if !collapsedButtons {
                Divider()
                HStack {
                    Group {
                        CollapsedButtons.labelStyle(.iconOnly)
                        ArrowsComponent(votableModel: postModel)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Divider()
            }
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet { commentBody in
                postModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
    }
    
    var CollapsedButtons: some View {
        Group {
            if !showInfo {
                PostButton(label: "Comments", image: "bubble.left.and.bubble.right") {
                    dismiss()
                    navModel.path.append(postModel)
                }
            }
            PostButton(label: postModel.saved ? "Unsave" : "Save", image: postModel.saved ? "bookmark.slash" : "bookmark") {
                try? haptics.fire()
                postModel.save(apiModel: apiModel)
            }
            PostButton(label: "Reply", image: "arrowshape.turn.up.left") {
                showingReply = true
            }
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
