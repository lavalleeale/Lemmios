import AlertToast
import SwiftUI

struct PostCreateComponent<T: PostDataReceiver>: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var apiModel: ApiModel
    @State var title = ""
    @State var postData = ""
    @State var postUrl = ""
    @State var showToast = false

    @ObservedObject var dataModel: T

    var body: some View {
        NavigationView {
            Form(content: {
                TextField("Title", text: $title)
                ImageSelector(url: $postUrl, optional: true)
                NavigationLink(postData == "" ? "Text (optional)" : postData) {
                    CustomTextEditorComponent(text: $postData)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .lineLimit(1)
                .foregroundStyle(postData == "" ? .secondary : .primary)
            })
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        let url = URL(string: postUrl)
                        if postUrl != "" && (url == nil || !UIApplication.shared.canOpenURL(url!)) {
                            showToast = true
                        } else {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.prepare()
                            impact.impactOccurred()
                            dataModel.receivePostData(title: title, content: postData, url: postUrl, apiModel: apiModel)
                            dismiss()
                        }
                    }
                }
            })
        }
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Invalid URL")
        }
    }
}

protocol PostDataReceiver: ObservableObject {
    func receivePostData(title: String, content: String, url: String, apiModel: ApiModel)
}
