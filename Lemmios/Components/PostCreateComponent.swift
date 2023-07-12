import AlertToast
import PhotosUI
import SimpleHaptics
import SwiftUI

struct PostCreateComponent: View {
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var apiModel: ApiModel
    @State var title = ""
    @State var postData = ""
    @State var postUrl = ""
    @State var showToast = false

    @StateObject var imageModel = ImageModel()
    @ObservedObject var postsModel: PostsModel
    var editingId: Int?

    var body: some View {
        NavigationView {
            Form(content: {
                TextField("Title", text: $title)
                GeometryReader { geo in
                    HStack {
                        TextField("URL (optional)", text: $postUrl)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .textContentType(.URL)
                            .autocorrectionDisabled(true)
                        PhotosPicker(selection: Binding(get: { nil }, set: { imageModel.setImage(imageSelection: $0, apiModel: apiModel) }),
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Image(systemName: "camera")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(5)
                                .frame(height: geo.size.height)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                if case let .success(_, image) = imageModel.imageState {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                withAnimation {
                                    imageModel.delete(apiModel: apiModel)
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .padding(3)
                            }
                            .background(.gray)
                            .clipShape(Circle())
                            .padding([.trailing, .top], -11.5)
                        }
                } else if case let .uploading(progress, image) = imageModel.imageState {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .overlay(alignment: .bottom) {
                            ProgressView(value: progress)
                                .padding()
                        }
                } else if case .failure = imageModel.imageState {
                    Text("test")
                }
                if imageModel.imageState.isError {
                    Text("test1")
                }
                NavigationLink(postData == "" ? "Text (optional)" : postData) {
                    TextEditor(text: $postData)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .lineLimit(1)
                .foregroundStyle(postData == "" ? .secondary : .primary)
            })
            .onChange(of: imageModel.imageState) { newValue in
                if case let .success(url, _) = newValue {
                    self.postUrl = "\(apiModel.url)/pictrs/image/\(url.file)"
                } else if case .empty = newValue {
                    self.postUrl = ""
                }
            }
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
                            if editingId == nil {
                                try? haptics.fire()
                                postsModel.createPost(title: title, content: postData, url: postUrl, apiModel: apiModel)
                                dismiss()
                            }
                        }
                    }
                }
            })
        }
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Invalid URL")
        }
        .toast(isPresenting: Binding(get: { imageModel.imageState.isError }, set: { _ in imageModel.imageState = .empty })) {
            if case let .failure(error) = imageModel.imageState {
                return AlertToast(displayMode: .alert, type: .error(.red), title: error.rawValue)
            } else {
                return AlertToast(displayMode: .alert, type: .error(.red), title: "Error loading image")
            }
        }
    }
}
