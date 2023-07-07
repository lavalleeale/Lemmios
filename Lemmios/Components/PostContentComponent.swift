import CachedAsyncImage
import LinkPresentation
import LinkPreview
import MarkdownUI
import SafariServices
import SwiftUI

let imageExtensions = ["png", "jpeg", "jpg", "heic", "bmp", "webp"]

struct PostContentComponent: View {
    @State var post: LemmyHttp.ApiPostData
    @State var preview: Bool
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        VStack {
            if let url = post.url, imageExtensions.contains(url.pathExtension) {
                CachedAsyncImage(url: preview ? post.thumbnail_url ?? url : url, content: { image in
                    image
                        .resizable()
                        .scaledToFit()
                }, placeholder: {
                    if !preview, let thumbnail_url = post.thumbnail_url {
                        CachedAsyncImage(url: thumbnail_url, content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                        }, placeholder: {
                            ProgressView()
                        })
                    } else {
                        ProgressView()
                    }
                })
            } else if let url = post.url {
                LinkPreview(url: url)
                    .frame(minHeight: 50)
            } else if preview, let body = post.body {
                HStack {
                    Markdown(processMarkdown(input: body, comment: false), baseURL: URL(string: apiModel.url)!)
                        .markdownTheme(Theme()
                            .text {
                                ForegroundColor(.secondary)
                            }
                            .link {
                                ForegroundColor(.blue)
                            }
                        )
                        .frame(maxHeight: 100, alignment: .top)
                        .clipped()
                    Spacer()
                }
            }
            if !preview, let body = post.body {
                Markdown(processMarkdown(input: body, comment: false), baseURL: URL(string: apiModel.url)!)
            }
        }
    }
}

struct LPLinkViewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> some UIView {
        let view = LPLinkView(url: url)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
