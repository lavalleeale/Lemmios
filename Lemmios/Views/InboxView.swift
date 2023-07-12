import SwiftUI

struct InboxView: View {
    @StateObject var inboxModel = InboxModel()
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var onlyUnread = true
    @State var showing = InboxSections.Replies
    var body: some View {
        ColoredListComponent {
            Section {
                Toggle("Unread only", isOn: $onlyUnread)
                    .onChange(of: onlyUnread) { newValue in
                        inboxModel.reset()
                        inboxModel.getMessages(apiModel: apiModel, onlyUnread: newValue)
                        inboxModel.getReplies(apiModel: apiModel, onlyUnread: newValue)
                    }
                Picker("Type", selection: $showing) {
                    ForEach(InboxSections.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section {
                Group {
                    switch showing {
                    case .Replies:
                        Group {
                            ForEach(Array(inboxModel.replies.enumerated()), id: \.element.id) { index, reply in
                                CommentComponent(commentModel: CommentModel(comment: reply, children: []), preview: true, replyInfo: reply.comment_reply!, depth: 0, read: {
                                    if reply.comment_reply!.read {
                                        apiModel.unreadCount += 1
                                    } else {
                                        apiModel.unreadCount -= 1
                                    }
                                    UIApplication.shared.applicationIconBadgeNumber = apiModel.unreadCount
                                    inboxModel.replies[index].comment_reply!.read.toggle()
                                }, collapseParent: nil)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .onAppear {
                                        if reply.id == inboxModel.replies.last!.id {
                                            inboxModel.getReplies(apiModel: apiModel, onlyUnread: onlyUnread)
                                        }
                                    }
                            }
                            if case .failed = inboxModel.repliesStatus {
                                HStack {
                                    Text("Lemmy Request Failed, ")
                                    Button("refresh?") {
                                        inboxModel.reset()
                                        inboxModel.getReplies(apiModel: apiModel, onlyUnread: onlyUnread)
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
                    case .Messages:
                        Group {
                            ForEach(Array(inboxModel.messages.enumerated()), id: \.element.id) { _, message in
                                MessageComponent(message: message)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .onAppear {
                                        if message.id == inboxModel.messages.last!.id {
                                            inboxModel.getMessages(apiModel: apiModel, onlyUnread: onlyUnread)
                                        }
                                    }
                            }
                            if case .failed = inboxModel.messagesStatus {
                                HStack {
                                    Text("Lemmy Request Failed, ")
                                    Button("refresh?") {
                                        inboxModel.reset()
                                        inboxModel.getMessages(apiModel: apiModel, onlyUnread: onlyUnread)
                                    }
                                }
                            } else if case .done = inboxModel.messagesStatus {
                                HStack {
                                    Text("Last Message Found ):")
                                }
                            } else if case .loading = inboxModel.messagesStatus {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            inboxModel.reset()
            inboxModel.getReplies(apiModel: apiModel, onlyUnread: onlyUnread)
            inboxModel.getMessages(apiModel: apiModel, onlyUnread: onlyUnread)
        }
        .onAppear {
            if inboxModel.replies.isEmpty {
                inboxModel.getReplies(apiModel: apiModel, onlyUnread: onlyUnread)
            }
            if inboxModel.messages.isEmpty {
                inboxModel.getMessages(apiModel: apiModel, onlyUnread: onlyUnread)
            }
        }
        .onChange(of: apiModel.selectedAccount) { newValue in
            inboxModel.reset()
            inboxModel.getReplies(apiModel: apiModel, onlyUnread: onlyUnread)
            inboxModel.getMessages(apiModel: apiModel, onlyUnread: onlyUnread)
        }
    }
}

enum InboxSections: String, CaseIterable {
    case Replies, Messages
}
