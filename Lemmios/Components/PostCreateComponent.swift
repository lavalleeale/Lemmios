import AlertToast
import SwiftUI
import SimpleHaptics

struct PostCreateComponent: View {
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var apiModel: ApiModel
    @State var postType = PostType.Link
    @State var title = ""
    @State var postData = ""
    @State var showToast = false
    @ObservedObject var postsModel: PostsModel
    var editingId: Int?
    
    var body: some View {
        NavigationView {
            Form(content: {
                Picker("Appearance", selection: $postType) {
                    ForEach(PostType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Title", text: $title)
                switch postType {
                case .Link:
                    TextField("URL", text: $postData)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                        .autocorrectionDisabled(true)
                case .Text:
                    NavigationLink(postData == "" ?"Text (optional)" : postData) {
                        TextEditor(text: $postData)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .lineLimit(1)
                    .foregroundStyle(postData == "" ? .secondary : .primary)
                }
            })
            .toast(isPresenting: $showToast) {
                AlertToast(displayMode: .hud, type: .error(.red), title: "Invalid URL")
            }
            .navigationTitle("Create \(postType.rawValue) Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        let url = URL(string: postData)
                        if postType == .Link && (url == nil || !UIApplication.shared.canOpenURL(url!)) {
                            showToast = true
                        } else {
                            if editingId == nil {
                                try? haptics.fire()
                                postsModel.createPost(type: postType, title: title, content: postData, apiModel: apiModel)
                                dismiss()
                            }
                        }
                    }
                }
            })
        }
    }
}

enum PostType: String, CaseIterable {
    case /* Photo, */ Link, Text
}
