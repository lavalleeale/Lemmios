import SwiftUI
import LemmyApi

struct UserHeaderComponent: View {
    let person_view: LemmyApi.ApiUser?
    var body: some View {
        HStack {
            if let person_view = person_view {
                VStack {
                    Text(String(person_view.counts.comment_score))
                    Text("Comment Score")
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text(String(person_view.counts.post_score))
                    Text("Post Score")
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text(person_view.person.published.relativeDateAsString())
                    Text("Account Age")
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
            }
        }
    }
}
