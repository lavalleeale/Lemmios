import CachedAsyncImage
import ImageViewerRemote
import LinkPresentation
import LinkPreview
import MarkdownUI
import SafariServices
import SwiftUI

let imageExtensions = ["png", "jpeg", "jpg", "heic", "bmp", "webp"]

struct PostContentComponent: View {
    @ObservedObject var post: PostModel
    @AppStorage("blurNSFW") var blurNsfw = true
    @State var preview: Bool
    @State var showingNSFW = false
    @State var showingImage = false
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var apiModel: ApiModel

    var previewType: LinkPreviewType = .auto

    var body: some View {
        VStack {
            if let url = post.post.url, imageExtensions.contains(url.pathExtension) {
                CachedAsyncImage(url: preview ? post.post.thumbnail_url ?? url : url, urlCache: .imageCache, content: { image in
                    image
                        .resizable()
                        .scaledToFit()
                }, placeholder: {
                    if !preview, let thumbnail_url = post.post.thumbnail_url {
                        CachedAsyncImage(url: thumbnail_url, urlCache: .imageCache, content: { image in
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
                .blur(radius: !blurNsfw || showingNSFW || !post.post.nsfw ? 0 : 20)
                .padding(!blurNsfw || showingNSFW || !post.post.nsfw ? 0 : 20)
                .highPriorityGesture(TapGesture().onEnded {
                    if !blurNsfw || showingNSFW || !post.post.nsfw {
                        showingImage = true
                    }
                    withAnimation(.linear(duration: 0.1)) {
                        showingNSFW = true
                    }
                })
                .overlay(alignment: .topLeading) {
                    if post.post.nsfw && blurNsfw {
                        Button {
                            withAnimation(.linear(duration: 0.1)) {
                                showingNSFW.toggle()
                            }
                        } label: {
                            Label(showingNSFW ? "Hide content" : "Show content", systemImage: showingNSFW ? "eye.slash" :  "eye")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.bordered)
                        .padding(3)
                    }
                }
                .fullScreenCover(isPresented: $showingImage) {
                    ImageViewerRemote(imageURL: .constant(url.absoluteString), viewerShown: $showingImage, closeButtonTopRight: true) {
                        PostActionsComponent(postModel: post, showCommunity: false, showUser: false, collapsedButtons: false, showInfo: false)
                    }
                }
            } else if let url = post.post.url {
                LinkPreview(url: url)
                    .type(previewType)
                    .disabled(true)
                    .frame(minHeight: 50)
                    .blur(radius: !blurNsfw || showingNSFW || !post.post.nsfw ? 0 : 20)
                    .padding(!blurNsfw || showingNSFW || !post.post.nsfw ? 0 : 20)
                    .highPriorityGesture(TapGesture().onEnded {
                        if !blurNsfw || showingNSFW || !post.post.nsfw {
                            openURL(url)
                        }
                        withAnimation {
                            showingNSFW = true
                        }
                    })
            } else if preview, let body = post.post.body {
                HStack {
                    Markdown(processMarkdown(input: body, stripImages: true), baseURL: URL(string: apiModel.url)!)
                        .markdownTheme(MarkdownUI.Theme()
                            .text {
                                ForegroundColor(.secondary)
                            }
                            .link {
                                ForegroundColor(.blue)
                            }
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxHeight: 100, alignment: .top)
                        .clipped()
                    Spacer()
                }
            }
            if !preview, let body = post.post.body {
                Markdown(processMarkdown(input: body, stripImages: false), baseURL: URL(string: apiModel.url)!)
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
