import SwiftUI
import LemmyApi

struct MessageComponent: View {
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var message: LemmyApi.Message
    @State var showingReply = false
    @ObservedObject var messageModel = MessageModel()

    var body: some View {
        VStack {
            HStack {
                UserLink(user: message.creator)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                    Text(message.private_message.published.relativeDateAsString())
                }
                Image(systemName: message.private_message.read ? "envelope.open" : "envelope.badge")
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(processMarkdown(input: message.private_message.content, stripImages: false))
                Spacer()
            }
        }
        .padding()
        .addSwipe(leadingOptions: [], trailingOptions: [SwipeOption(id: "read", image: message.private_message.read ? "envelope.badge" : "envelope.open", color: Color(hex: "3880EF")!), SwipeOption(id: "reply", image: "arrowshape.turn.up.left", color: .blue)]) { option in
            if option == "read" {
                messageModel.read(message: message.private_message, apiModel: apiModel) {
                    if message.private_message.read {
                        apiModel.unreadCount += 1
                    } else {
                        apiModel.unreadCount -= 1
                    }
                    UIApplication.shared.applicationIconBadgeNumber = apiModel.unreadCount
                    self.message.private_message.read.toggle()
                }
            } else {
                self.showingReply = true
            }
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet(title: "Send Message") { commentBody in
                messageModel.send(to: message.creator.id, content: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
    }
}
