import SwiftUI
import LemmyApi

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
            VStack(spacing: 0) {
                if let post = item as? LemmyApi.PostView {
                    PostPreviewComponent(post: post, showCommunity: true, showUser: false)
                }
                if let comment = item as? LemmyApi.CommentView {
                    let model = CommentModel(comment: comment, children: [])
                    CommentComponent(parent: model, commentModel: model, preview: true, depth: 0, collapseParent: nil)
                }
                Rectangle()
                    .fill(.secondary.opacity(0.1))
                    .frame(maxWidth: .infinity, maxHeight: 10)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .onAppear {
                if item.id == withCounts.last!.id {
                    fetchMore()
                }
            }
        }
    }
}
