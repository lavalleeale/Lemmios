import SwiftUI

struct UserView: View {
    @EnvironmentObject var apiModel: ApiModel
    @ObservedObject var userModel: UserModel
    var body: some View {
        let apiHost = URL(string: apiModel.url)!.host()!
        let split = userModel.name.split(separator: "@")
        if let name = split.first, let from = split.last {
            List {
                if userModel.userData != nil {
                    HStack {
                        VStack {
                            Text(String(userModel.userData!.person_view.counts.comment_score))
                            Text("Comment Score")
                                .foregroundStyle(.secondary)
                        }
                        VStack {
                            Text(String(userModel.userData!.person_view.counts.post_score))
                            Text("Post Score")
                                .foregroundStyle(.secondary)
                        }
                        VStack {
                            Text(userModel.userData!.person_view.person.published.relativeDateAsString())
                            Text("Account Age")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    // List separators don't work with infiinite width
                    Divider()
                        .listRowSeparator(.hidden)
                    let withCounts = userModel.userData!.posts.map { $0 as any WithCounts } + userModel.userData!.comments.map { $0 as any WithCounts }.sorted { $0.counts.published > $1.counts.published }
                    ForEach(withCounts, id: \.id) { item in
                        VStack {
                            if let post = item as? LemmyHttp.ApiPost {
                                PostPreviewComponent(post: post, showCommunity: true, showUser: false)
                            }
                            if let comment = item as? LemmyHttp.ApiComment {
                                CommentComponent(commentModel: CommentModel(comment: comment, children: []), preview: true, depth: 0, collapseParent: nil)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .onFirstAppear {
                userModel.fetchData(apiModel: apiModel)
            }
            .navigationTitle(from == apiHost ? String(name) : userModel.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("This should never be seen")
        }
    }
}
