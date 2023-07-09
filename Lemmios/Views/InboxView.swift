import SwiftUI

struct InboxView: View {
    @ObservedObject var inboxModel: InboxModel
    @EnvironmentObject var apiModel: ApiModel
    @State var onlyUnread = true
    var body: some View {
        ColoredListComponent {
            Section {
                Toggle("Unread only", isOn: $onlyUnread)
                    .onChange(of: onlyUnread) { newValue in
                        inboxModel.reset()
                        inboxModel.getData(apiModel: apiModel, onlyUnread: newValue)
                    }
            }
            Section {
                ForEach(Array(inboxModel.replies.enumerated()), id: \.element.id) { index, reply in
                    CommentComponent(commentModel: CommentModel(comment: reply.element1, children: []), preview: true, replyInfo: reply.element2.comment_reply, depth: 0, read: {
                        if reply.comment_reply.read {
                            apiModel.unreadCount += 1
                        } else {
                            apiModel.unreadCount -= 1
                        }
                        inboxModel.replies[index].comment_reply.read.toggle()
                    }, collapseParent: nil)
                        .onAppear {
                            if reply.id == inboxModel.replies.last!.id {
                                inboxModel.getData(apiModel: apiModel, onlyUnread: onlyUnread)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                if case .failed = inboxModel.repliesStatus {
                    HStack {
                        Text("Lemmy Request Failed, ")
                        Button("refresh?") {
                            inboxModel.reset()
                            inboxModel.getData(apiModel: apiModel, onlyUnread: onlyUnread)
                        }
                    }
                } else if case .done = inboxModel.repliesStatus {
                    HStack {
                        Text("Last Reply Found ):")
                    }
                } else if case .loading = inboxModel.repliesStatus {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .refreshable {
            inboxModel.reset()
            inboxModel.getData(apiModel: apiModel, onlyUnread: onlyUnread)
        }
        .onAppear {
            if inboxModel.replies.isEmpty {
                inboxModel.getData(apiModel: apiModel, onlyUnread: onlyUnread)
            }
        }
    }
}
