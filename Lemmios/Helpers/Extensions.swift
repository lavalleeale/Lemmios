import Foundation
import SwiftUI
import SwiftUIKit
import WebKit

extension Date {
    func relativeDateAsString() -> String {
        let df = RelativeDateTimeFormatter()
        var dateString: String = df.localizedString(for: self, relativeTo: Date())
        dateString = dateString.replacingOccurrences(of: "months", with: "M")
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

let communityRegex = /^https:\/\/(.+?)\/c\/([a-z_]+)(@[a-z\-.]+)?$/
let userRegex = /^https:\/\/(.+?)\/u\/([a-zA-Z_]+)(@[a-z\-.]+)?$/

public extension View {
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
    }

    internal func addSwipe(leadingOptions: [SwipeOption], trailingOptions: [SwipeOption], action: @escaping (String) -> ()) -> some View {
        return modifier(SwiperContainer(leadingOptions: leadingOptions, trailingOptions: trailingOptions, action: action))
    }

    func popupNavigationView<Label: View>(isPresented: Binding<Bool>, heightRatio: CGFloat = 2.0, widthRatio: CGFloat = 1.25, @ViewBuilder label: () -> Label) -> some View {
        modifier(PopupNavigationView(show: isPresented, heightRatio: heightRatio, widthRatio: widthRatio, label: label))
    }

    func commentDepthIndicator(depth: Int) -> some View {
        padding(.leading, 10)
            .overlay(Rectangle()
                .frame(width: CGFloat(depth.signum()), height: nil, alignment: .leading)
                .foregroundColor(colors[depth % colors.count]), alignment: .leading)
            .padding(.leading, 10 * CGFloat(depth))
            .frame(idealWidth: UIScreen.main.bounds.width - CGFloat(10 * depth), alignment: .leading)
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
    @ObservedObject var navModel: NavModel
    @State var url: URL?

    func body(content: Content) -> some View {
        NavigationStack(path: $navModel.path) {
            content
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
                .fullScreenCover(item: $url) { item in
                    PostUrlViewWrapper(url: item)
                        .ignoresSafeArea()
                }
        }
        .environmentObject(navModel)
        .environment(\.openURL, OpenURLAction { url in
            if let match = url.absoluteString.firstMatch(of: communityRegex) {
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
    let action: () -> ()

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

    let action: (String) -> ()

    var body: some View {
        NavigationView {
            TextEditor(text: $commentBody)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Add Comment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            commentSize = .large
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            commentSize = .large
                            dismiss()
                            action(commentBody)
                        }
                    }
                }
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
