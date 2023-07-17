import CachedAsyncImage
import ImageViewer
import LinkPresentation
import LinkPreview
import MarkdownUI
import SafariServices
import SwiftUI

let imageExtensions = ["png", "jpeg", "jpg", "heic", "bmp", "webp"]

struct PostContentComponent: View {
    @ObservedObject var post: PostModel
    @AppStorage("blurNSFW") var blurNsfw = true
    @AppStorage("compact") var compact = false
    let preview: Bool
    @State var showingNSFW = false
    @State var showingImage = false
    @Environment(\.openURL) private var openURL
    @Environment(\.redactionReasons) private var reasons
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        let showCompact = compact && preview
        Group {
            if let url = post.post.url, imageExtensions.contains(url.pathExtension) {
                CachedAsyncImage(url: preview ? post.post.thumbnail_url ?? url : url, urlCache: .imageCache, content: { image in
                    image
                        .resizable()
                        .aspectRatio(showCompact ? 1 : nil, contentMode: showCompact ? .fill : .fit)
                        .clipped()
                        .cornerRadius(showCompact ? 12 : 0)
                }, placeholder: {
                    if !preview, let thumbnail_url = post.post.thumbnail_url {
                        CachedAsyncImage(url: thumbnail_url, urlCache: .imageCache, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: showCompact ? .fill : .fit)
                        }, placeholder: {
                            ProgressView()
                                .hidden(if: reasons.contains(.screenshot))
                        })
                    } else {
                        ProgressView()
                            .hidden(if: reasons.contains(.screenshot))
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
                            Label(showingNSFW ? "Hide content" : "Show content", systemImage: showingNSFW ? "eye.slash" : "eye")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.bordered)
                        .padding(3)
                    }
                    ImageViewComponent(url: url, urlCache: .imageCache, showing: $showingImage) {
                        PostActionsComponent(postModel: post, showCommunity: false, showUser: false, collapsedButtons: false, rowButtons: true, showInfo: false, image: true, preview: false)
                    }
                }
            } else if let url = post.post.url {
                LinkPreview(url: url)
                    .type(showCompact ? .small : .large)
                    .disabled(true)
                    .frame(maxHeight: showCompact ? 100 : nil)
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
                if showCompact {
                    Image(systemName: "text.aligncenter")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                } else {
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
