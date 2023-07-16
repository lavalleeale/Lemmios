import LemmyApi
import LinkPresentation
import SwiftUI
import UIKit

struct PostSharePreview: View {
    @ObservedObject var postModel: PostModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @EnvironmentObject var apiModel: ApiModel
    @State var showUsernames = true
    @State var showCommunities = true

    typealias imageRendererType = SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<Lemmios.PostSharePreviewContent, SwiftUI._EnvironmentKeyWritingModifier<SwiftUI.ColorScheme>>, SwiftUI._EnvironmentKeyWritingModifier<Lemmios.ApiModel?>>, SwiftUI._EnvironmentKeyWritingModifier<Swift.Bool>>, SwiftUI._EnvironmentKeyWritingModifier<Swift.Bool>>

    var comments: [LemmyApi.ApiComment]
    @StateObject var postShareModel = PostShareModel<imageRendererType>()

    init(postModel: PostModel, isPresented: Binding<Bool>, comments: [LemmyApi.ApiComment]) {
        self.postModel = postModel
        self._isPresented = isPresented
        self.comments = comments
    }

    var body: some View {
        Rectangle().frame(width: 0, height: 0).clipped().sheet(isPresented: $isPresented) {
            VStack {
                if let imageRenderer = postShareModel.imageRenderer, let uiImage = imageRenderer.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Toggle("Show Usernames", isOn: $showUsernames)
                    Toggle("Show Communities", isOn: $showCommunities)
                    Button {
                        alwaysShare(item: ItemDetailSource(name: postModel.post.name, image: uiImage))
                    } label: {
                        Label {
                            Text("Share")
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(ImageShareButtonStyle())
                }
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onChange(of: comments) { _ in
            update()
        }
        .onChange(of: systemColorScheme) { newValue in
            update(colorScheme: newValue)
        }
        .onChange(of: showUsernames) { _ in
            update()
        }
        .onChange(of: showCommunities) { _ in
            update()
        }
        .onAppear {
            update()
        }
    }

    func update(colorScheme: SwiftUI.ColorScheme? = nil) {
        postShareModel.updateRenderer(newBody: PostSharePreviewContent(postModel: postModel, comments: comments)
            .environment(\.colorScheme, colorScheme ?? systemColorScheme)
            .environmentObject(apiModel)
            .environment(\.showCommunities, showCommunities)
            .environment(\.showUsernames, showUsernames)
            as! imageRendererType)
    }
}

struct ImageShareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PostSharePreviewContent: View {
    @ObservedObject var postModel: PostModel
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @EnvironmentObject var apiModel: ApiModel
    let comments: [LemmyApi.ApiComment]
    var body: some View {
            let image = postModel.post.url != nil && imageExtensions.contains(postModel.post.url!.pathExtension)
            VStack(alignment: .leading) {
                if !image {
                    Text(postModel.post.name)
                        .font(.title)
                        .padding()
                }
                PostContentComponent(post: postModel, preview: false)
                    .if(!image) { view in
                        view.padding(.horizontal)
                    }
                VStack(alignment: .leading) {
                    if image {
                        Text(postModel.post.name)
                            .font(.title)
                    }
                    PostActionsComponent(postModel: postModel, showCommunity: true, showUser: true, collapsedButtons: false, rowButtons: false, preview: true)
                }
                .padding()
                VStack(spacing: 0) {
                    ForEach(comments) { comment in
                        CommentComponent(commentModel: CommentModel(comment: comment, children: []), preview: true, depth: comment.comment.path.components(separatedBy: ".").count - 2, collapseParent: nil)
                    }
                }
            }
            .environmentObject(apiModel)
        .background(selectedTheme.primaryColor)
        .frame(width: UIScreen.main.bounds.width)
        .environment(\.colorScheme, systemColorScheme)
        .redacted(reason: .screenshot)
    }
}

public extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(rootViewController)
    }

    static func getVisibleViewControllerFrom(_ vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(pvc)
            } else {
                return vc
            }
        }
    }
}

class ItemDetailSource: NSObject {
    let name: String
    let image: UIImage

    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }
}

extension ItemDetailSource: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metaData = LPLinkMetadata()
        metaData.title = name
        metaData.imageProvider = NSItemProvider(object: image)
        return metaData
    }
}
