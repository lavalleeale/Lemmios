import CachedAsyncImage
import SwiftUI

struct PostActionsComponent: View {
    @State var showingCommunity = false
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel

    let showCommunity: Bool
    let showUser: Bool
    let showButtons: Bool

    var body: some View {
        let communityHost = postModel.post.community.actor_id.host()!
        let userHost = postModel.post.creator.actor_id.host()!
        let apiHost = URL(string: apiModel.url)!.host()!
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if showCommunity {
                        if postModel.post.community.icon != nil {
                            CachedAsyncImage(url: URL(string: postModel.post.community.icon!), content: { image in
                                image
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }, placeholder: {
                                ProgressView()
                            })
                        }
                        HStack(spacing: 0) {
                            if communityHost != apiHost {
                                Text("\(postModel.post.community.name)\(Text("@\(communityHost)").foregroundColor(.secondary))")
                                    .lineLimit(1)
                            } else {
                                Text(postModel.post.community.name)
                                    .lineLimit(1)
                            }
                        }
                        .highPriorityGesture(TapGesture().onEnded {
                            showingCommunity = true
                        })
                    }
                    if showUser {
                        HStack(spacing: 0) {
                            if userHost != apiHost {
                                Text("by \(postModel.post.creator.name)\(Text("@\(userHost)").foregroundColor(.secondary))")
                                    .lineLimit(1)
                            } else {
                                Text("by \(postModel.post.creator.name)")
                                    .lineLimit(1)
                            }
                        }
                        .highPriorityGesture(TapGesture().onEnded {
                            showingCommunity = true
                        })
                    }
                }
                HStack {
                    ScoreComponent(votableModel: postModel)
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        NumberComponent(num: postModel.post.counts.comments)
                        Image(systemName: "clock")
                        Text(postModel.post.counts.published.date()!.relativeDateAsString())
                    }
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if showButtons {
                ArrowsComponent(votableModel: postModel)
            }
        }
        .navigationDestination(isPresented: $showingCommunity) {
            if (communityHost == apiHost) {
            } else {
                PostsView(postsModel: PostsModel(apiModel: apiModel, path: "\(postModel.post.community.name)@\(communityHost)"))                
            }
        }
    }
}
