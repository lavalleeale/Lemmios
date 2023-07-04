import SafariServices
import SwiftUI
import MarkdownUI
import CachedAsyncImage

struct PostContentComponent: View {
    @State var post: LemmyHttp.ApiPost
    @State var preview: Bool
    @State private var showSafari: Bool = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack {
            if let thumbnail_url = post.post.thumbnail_url, let url = post.post.url {
                CachedAsyncImage(url: URL(string: preview ? thumbnail_url : url)!, content: { image in
                    image
                        .resizable()
                        .scaledToFit()
                }, placeholder: {
                    ProgressView()
                })
            } else if let urlText = post.post.url, let url = URL(string: urlText) {
                Button {} label: {
                    HStack {
                        Text(url.host(percentEncoded: false)!)
                            .foregroundColor(Color.primary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding()
                    .frame(minHeight: 50)
                    .background(Color.secondary.opacity(0.3))
                    .cornerRadius(10)
                }
                .highPriorityGesture(
                    TapGesture().onEnded {
                        showSafari.toggle()
                    })
                .fullScreenCover(isPresented: $showSafari, content: {
                    PostUrlViewWrapper(url: url)
                })
            } else if preview, let body = post.post.body {
                HStack {
                    Markdown(body)
                        .markdownTextStyle {
                            ForegroundColor(.secondary)
                        }
                        .frame(maxHeight: 100, alignment: .top)
                        .clipped()
                    Spacer()
                }
            }
            if !preview, let body = post.post.body {
                    Markdown(body)
            }
        }
    }
}

struct PostUrlViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<PostUrlViewWrapper>) {}
}
