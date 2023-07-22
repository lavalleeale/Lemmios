import Foundation
import ImageViewer
import LemmyApi
import SwiftUI
import SwiftUIKit
import WebKit

extension Date {
    func relativeDateAsString() -> String {
        let df = RelativeDateTimeFormatter()
        var dateString: String = df.localizedString(for: self, relativeTo: Date())
        dateString = dateString.replacingOccurrences(of: "months", with: "M")
            .replacingOccurrences(of: "years", with: "y")
            .replacingOccurrences(of: "month", with: "M")
            .replacingOccurrences(of: "weeks", with: "w")
            .replacingOccurrences(of: "week", with: "w")
            .replacingOccurrences(of: "days", with: "d")
            .replacingOccurrences(of: "day", with: "d")
            .replacingOccurrences(of: "seconds", with: "s")
            .replacingOccurrences(of: "second", with: "s")
            .replacingOccurrences(of: "minutes", with: "m")
            .replacingOccurrences(of: "minute", with: "m")
            .replacingOccurrences(of: "hours", with: "h")
            .replacingOccurrences(of: "hour", with: "h")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "ago", with: "")
        return dateString
    }
}

public extension View {
    internal func splashStyle(_ selectedTheme: Theme) -> some View {
        padding()
            .buttonStyle(.bordered)
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(selectedTheme.backgroundColor)
    }

    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppear(action: action))
    }

    internal func addSwipe(leadingOptions: [SwipeOption], trailingOptions: [SwipeOption], compressable: Bool = true, action: @escaping (String) -> Void) -> some View {
        return modifier(SwiperContainer(leadingOptions: leadingOptions, trailingOptions: trailingOptions, compressable: compressable, action: action))
    }

    func popupNavigationView<Label: View>(isPresented: Binding<Bool>, heightRatio: CGFloat = 2.0, widthRatio: CGFloat = 1.25, @ViewBuilder label: () -> Label) -> some View {
        modifier(PopupNavigationView(show: isPresented, heightRatio: heightRatio, widthRatio: widthRatio, label: label))
    }

    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func commentDepthIndicator(depth: Int) -> some View {
        ZStack {
            if depth > 0 {
                padding(.leading, 10)
                    .overlay(Rectangle()
                        .frame(width: CGFloat(depth.signum()), height: nil, alignment: .leading)
                        .foregroundColor(colors[depth % colors.count]), alignment: .leading)
                    .padding(.leading, 10 * CGFloat(depth - 1))
                    .frame(idealWidth: UIScreen.main.bounds.width - CGFloat(10 * depth - 1), alignment: .leading)
            } else {
                self
            }
        }
    }

    internal func handleNavigations(navModel: NavModel) -> some View {
        modifier(WithNavigationModifier(navModel: navModel))
    }

    func presentationDetent(
        _ detents: [PresentationDetentReference],
        largestUndimmed: PresentationDetentReference,
        selection: Binding<PresentationDetent>? = nil
    ) -> some View {
        modifier(
            PresentationDetentsViewModifier(
                presentationDetents: detents + [largestUndimmed],
                largestUndimmed: largestUndimmed,
                selection: selection
            )
        )
    }
}

private struct WithNavigationModifier: ViewModifier {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @ObservedObject var navModel: NavModel
    @State var url: URL?
    @State var imageUrl: URL?

    func body(content: Content) -> some View {
        NavigationStack(path: $navModel.path) {
            content
                .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
                .toolbar(.visible, for: .tabBar)
                .navigationDestination(for: PostsModel.self) { postsModel in
                    PostsView(postsModel: postsModel)
                }
                .navigationDestination(for: PostModel.self) { postModel in
                    PostView(postModel: postModel)
                }
                .navigationDestination(for: UserModel.self) { userModel in
                    UserView(userModel: userModel)
                }
                .navigationDestination(for: SearchedModel.self) { searchedModel in
                    SearchedView(searchedModel: searchedModel)
                }
                .navigationDestination(for: ResolveModel<LemmyApi.PostView>.self) { resolveModel in
                    ResolveView(resolveModel: resolveModel)
                }
                .navigationDestination(for: ResolveModel<LemmyApi.CommentView>.self) { resolveModel in
                    ResolveView(resolveModel: resolveModel)
                }
                .fullScreenCover(item: $url) { item in
                    PostUrlViewWrapper(url: item)
                        .ignoresSafeArea()
                }
            ImageViewComponent(url: imageUrl ?? URL(string: "google.com")!, urlCache: .imageCache, showing: Binding(get: { imageUrl != nil }, set: { _ in imageUrl = nil })) {}
        }
        .environmentObject(navModel)
        .environment(\.openURL, OpenURLAction { url in
            if imageExtensions.contains(url.pathExtension) {
                self.imageUrl = url
            } else if let match = url.absoluteString.firstMatch(of: communityRegex) {
                if let instance = match.3 {
                    navModel.path.append(PostsModel(path: "\(match.2)\(instance)"))
                } else {
                    navModel.path.append(PostsModel(path: "\(match.2)@\(match.1)"))
                }
            } else if let match = url.absoluteString.firstMatch(of: userRegex) {
                if let instance = match.3 {
                    navModel.path.append(UserModel(path: "\(match.2)\(instance)"))
                } else {
                    navModel.path.append(UserModel(path: "\(match.2)@\(match.1)"))
                }
            } else if url.absoluteString.firstMatch(of: postRegex) != nil {
                navModel.path.append(ResolveModel<LemmyApi.PostView>(thing: url))
            } else if url.absoluteString.firstMatch(of: commentRegex) != nil {
                navModel.path.append(ResolveModel<LemmyApi.CommentView>(thing: url))
            } else {
                self.url = url
            }
            return .handled
        })
    }
}

struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .secondaryLabel.withAlphaComponent(0.1)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private struct PopupNavigationView<Label>: ViewModifier where Label: View {
    @Binding var show: Bool

    let heightRatio: CGFloat
    let widthRatio: CGFloat

    @ViewBuilder var label: Label

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $show) {
                let size = UIScreen.main.bounds
                NavigationView {
                    label
                }
                .background(.gray)
                .frame(width: size.width / widthRatio, height: size.height / heightRatio, alignment: .center)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(TransparentBackground().onTapGesture {
                    show = false
                })
            }
    }
}

private struct FirstAppear: ViewModifier {
    let action: () -> Void

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

struct CommentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var commentSize: PresentationDetent = .large
    @State var commentBody = ""
    @State var title: String

    let action: (String) -> Void

    var body: some View {
        NavigationView {
            TextEditor(text: $commentBody)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            commentSize = .large
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            commentSize = .large
                            dismiss()
                            action(commentBody)
                        }
                    }
                })
        }
    }
}

extension WKWebView {
    var refreshControl: UIRefreshControl? {
        (scrollView.getAllSubviews() as [UIRefreshControl]).first
    }

    func setPullToRefresh() {
        (scrollView.getAllSubviews() as [UIRefreshControl]).forEach {
            $0.removeFromSuperview()
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(webViewPullToRefreshHandler(source:)), for: .valueChanged)
        scrollView.addSubview(refreshControl)
    }

    @objc func webViewPullToRefreshHandler(source: UIRefreshControl) {
        guard let url = url else {
            source.endRefreshing()
            return
        }
        load(URLRequest(url: url))
    }
}

extension UIView {
    class func getAllSubviews<T: UIView>(from parentView: UIView) -> [T] {
        return parentView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T {
                result.append(view)
            }
            return result
        }
    }

    func getAllSubviews<T: UIView>() -> [T] {
        return UIView.getAllSubviews(from: self) as [T]
    }
}

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

public extension UIApplication {
    func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }

        let window = connectedScenes.first?
            .windows
            .first { $0.isKeyWindow }

        return window
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

private struct ShowUsernames: EnvironmentKey {
    static let defaultValue = true
}

private struct ShowCommunities: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var showUsernames: Bool {
        get { self[ShowUsernames.self] }
        set { self[ShowUsernames.self] = newValue }
    }

    var showCommunities: Bool {
        get { self[ShowCommunities.self] }
        set { self[ShowCommunities.self] = newValue }
    }
}

func withFeedback(
    _ style: UIImpactFeedbackGenerator.FeedbackStyle,
    _ action: @escaping () -> Void
) -> () -> Void {
    { () in
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.prepare()
        impact.impactOccurred()
        action()
    }
}

struct HapticTapGestureViewModifier: ViewModifier {
    var style: UIImpactFeedbackGenerator.FeedbackStyle
    var action: () -> Void

    func body(content: Content) -> some View {
        content.onTapGesture(perform: withFeedback(style, action))
    }
}

extension View {
    func onTapGesture(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(HapticTapGestureViewModifier(style: style, action: action))
    }

    func alwaysShare(item: Any) {
        let avc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        let sender = UIApplication.shared.currentUIWindow()!.visibleViewController!
        if UIDevice.current.userInterfaceIdiom == .pad {
            if avc.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
                avc.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                avc.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height, width: 0, height: 0)
                avc.popoverPresentationController?.permittedArrowDirections = [.left]
            }
        }
        sender.present(avc, animated: true)
    }
}

extension Button {
    init(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.init(action: withFeedback(style, action), label: label)
    }
}
