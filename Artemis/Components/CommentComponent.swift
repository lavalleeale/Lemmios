import MarkdownUI
import SwiftUI

let colors = [Color.green, Color.red, Color.orange, Color.yellow]

struct CommentComponent: View {
    @ObservedObject var commentModel: CommentModel
    @State var collapsed = false
    @State var showingThread = false
    @EnvironmentObject var post: PostModel
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        let depth = commentModel.comment.comment.path.components(separatedBy: ".").count - 2
        VStack {
            ZStack {
                VStack(alignment: .leading) {
                    HStack {
                        NavigationLink(commentModel.comment.creator.name) {
//                                UserView(username: comment.data!.author)
                        }
                        .accessibility(identifier: "\(commentModel.comment.creator.name) user button")
                        .foregroundColor(commentModel.comment.creator.id == commentModel.comment.post.creator_id ? Color.blue : Color.primary)
                            ScoreComponent(votableModel: commentModel)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    if !collapsed {
                        Markdown(commentModel.comment.comment.content)
                    }
                    Divider()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.linear(duration: 0.2)) {
                        collapsed.toggle()
                    }
                }
            }
            .padding(.leading, 5)
            .overlay(Rectangle()
                .frame(width: CGFloat(depth.signum()), height: nil, alignment: .leading)
                .foregroundColor(colors[depth % colors.count]), alignment: .leading)
            .padding(.leading, 10 * CGFloat(depth))
            .frame(idealWidth: UIScreen.main.bounds.width - CGFloat(10 * depth), alignment: .leading)
            .addSwipe(leadingOptions: [SwipeOption(id: "upvote", image: "arrow.up", color: .orange), SwipeOption(id: "downvote", image: "arrow.down", color: .purple)], trailingOptions: []) { swiped in
                if apiModel.selectedAccount == "" {
                    apiModel.getAuth()
                } else {
                    switch swiped {
                    case "upvote":
                        commentModel.vote(direction: true)
                    case "downvote":
                        commentModel.vote(direction: false)
                    default:
                        break
                    }
                }
            }
            if !collapsed {
                ForEach(commentModel.children.filter {isCommentParent(parentId: String(commentModel.comment.id), possibleChild: $0)}) { comment in
                    CommentComponent(commentModel: CommentModel(comment: comment, children: commentModel.children.filter {$0.comment.path.contains("\(commentModel.comment.id).")}, apiModel: apiModel))
                }
            }
        }
    }
}
