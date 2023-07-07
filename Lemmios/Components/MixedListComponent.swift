import SwiftUI

struct MixedListComponent: View {
    let withCounts: [any WithCounts]
    let fetchMore: () -> Void

    init(withCounts: [any WithCounts], fetchMore: @escaping () -> Void) {
        self.withCounts = withCounts
        self.fetchMore = fetchMore
        if withCounts.isEmpty {
            fetchMore()
        }
    }

    var body: some View {
        ForEach(withCounts.sorted { $0.counts.published > $1.counts.published }, id: \.id) { item in
            VStack {
                if let post = item as? LemmyHttp.ApiPost {
                    PostPreviewComponent(post: post, showCommunity: true, showUser: false)
                }
                if let comment = item as? LemmyHttp.ApiComment {
                    CommentComponent(commentModel: CommentModel(comment: comment, children: []), preview: true, depth: 0, collapseParent: nil)
                }
            }
            .onAppear {
                if item.id == withCounts.last!.id {
                    fetchMore()
                }
            }
        }
    }
}
