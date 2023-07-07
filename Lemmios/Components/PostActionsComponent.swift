import SimpleHaptics
import SwiftUI
import SwiftUIKit

struct PostActionsComponent: View {
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var showingReply = false
    
    let showCommunity: Bool
    let showUser: Bool
    let collapsedButtons: Bool
    
    var body: some View {
        let communityHost = postModel.community!.actor_id.host()!
        let userHost = postModel.creator!.actor_id.host()!
        let apiHost = URL(string: apiModel.url)!.host()!
        VStack {
            HStack {
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
            Button {
                if apiModel.selectedAccount == "" {
                    apiModel.getAuth()
                } else {
                    try? haptics.fire()
                    showingReply = true
                }
            } label: {
                Label {
                    Text("Comment")
                } icon: {
                    Image(systemName: "arrowshape.turn.up.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .padding(.all, 10)
                }
            }
            .foregroundStyle(.secondary)
            Button {
                if apiModel.selectedAccount == "" {
                    apiModel.getAuth()
                } else {
                    try? haptics.fire()
                    postModel.save(apiModel: apiModel)
                }
            } label: {
                Label {
                    Text(postModel.saved ? "Unsave" : "Save")
                } icon: {
                    Image(systemName: postModel.saved ? "bookmark.slash" : "bookmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .padding(.all, 10)
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}
