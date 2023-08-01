import SwiftUI
import PhotosUI
import AlertToast

struct ImageSelector: View {
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var imageModel = ImageModel()
    @Binding var url: String
    
    @State var showResize = false
    @State var size = 5000
    @State var showError = false
    
    let optional: Bool
    var body: some View {
        Group {
            GeometryReader { geo in
                HStack {
                    TextField("URL\(optional ? " (optional)" : "")", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                        .autocorrectionDisabled(true)
                    PhotosPicker(selection: Binding(get: { nil }, set: { imageModel.setImage(imageSelection: $0, targetSize: .max, apiModel: apiModel) }),
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
                Image(uiImage: image)
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
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 100)
                    .overlay(alignment: .bottom) {
                        ProgressView(value: progress)
                            .padding()
                    }
            }
        }
        .alert("Resize (kB)", isPresented: $showResize) {
            let formatter: NumberFormatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                return formatter
            }()
            TextField("Target Size (kB)", value: $size, formatter: formatter)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Resize") {
                if case let .failure(_, image) = imageModel.imageState, let image = image {
                    imageModel.loadImage(image, targetSize: size * 1024, apiModel: apiModel)
                }
            }
        }
        .onChange(of: imageModel.imageState) { newValue in
            if case let .success(url, _) = newValue {
                self.url = "\(apiModel.url)/pictrs/image/\(url.file)"
            } else if case .empty = newValue {
                self.url = ""
            }
        }
        .toast(isPresenting: $showError, duration: 10) {
            if case let .failure(error, _) = imageModel.imageState {
                return AlertToast(displayMode: .banner(.pop), type: .error(.red), title: error.rawValue)
            } else {
                return AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Error loading image")
            }
        } onTap: {
            if case let .failure(error, _) = imageModel.imageState {
                if error == .tooLarge || error == .resize {
                    self.showResize = true
                }
            }
        }
        .onChange(of: imageModel.imageState.isError) { newValue in
            if newValue == true {
                self.showError = true
            }
        }
    }
}
