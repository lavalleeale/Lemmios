import Foundation
import SwiftUI

struct RemindersView: View {
    @StateObject var remindersModel = RemindersModel()
    var body: some View {
        ColoredListComponent {
            if remindersModel.requests.isEmpty {
                Text("No reminders set")
            }
            ForEach(remindersModel.requests, id: \.date) { reminder in
                Group {
                    if case .post(let postData) = reminder.data {
                        NavigationLink(value: PostModel(post: postData)) {
                            VStack(alignment: .leading) {
                                Text("Post: \(postData.name)")
                                Text(DateFormatter.localizedString(from: reminder.date, dateStyle: .medium, timeStyle: .medium))
                            }
                        }
                    } else if case .comment(let commentData) = reminder.data {
                        NavigationLink(value: PostModel(post: commentData.post, comment: commentData)) {
                            VStack(alignment: .leading) {
                                Text("Comment: \(commentData.comment.content) in \(commentData.post.name)")
                                Text(DateFormatter.localizedString(from: reminder.date, dateStyle: .medium, timeStyle: .short))
                            }
                        }
                    }
                }
            }
            .onDelete { indexSet in
                remindersModel.requests.enumerated().forEach { (i, reminder) in
                    guard indexSet.contains(i) else {
                        return
                    }
                    remindersModel.remove(reminder)
                }
            }
        }
    }
}
