import AlertToast
import ImageViewer
import LemmyApi
import SafariServices
import SwiftUI

let communityRegex = /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/c\/([a-z_]+)(@[a-z\-.]+)?$/
let userRegex = /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/u\/([0-9a-zA-Z_]+)(@[a-z\-.]+)?$/
let postRegex = /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/post\/([0-9]+)$/
let commentRegex = /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/comment\/([0-9]+)$/

struct ContentView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("colorScheme") var colorScheme = ColorScheme.System
    @AppStorage("pureBlack") var pureBlack = false
    @AppStorage("splashAccepted") var splashAccepted = false
    @AppStorage("fontSize") var fontSize: Double = -1
    @AppStorage("systemFont") var systemFont = true

    @Environment(\.colorScheme) var systemColorScheme
    @Environment(\.dynamicTypeSize) var size: DynamicTypeSize

    @ObservedObject var selectedTab: StartingTab
    @ObservedObject var apiModel = ApiModel()
    @ObservedObject var homeNavModel = NavModel(startNavigated: true)
    @ObservedObject var searchNavModel = NavModel(startNavigated: false)
    @ObservedObject var userNavModel = NavModel(startNavigated: false)
    @ObservedObject var settingsNavModel = NavModel(startNavigated: false)
    @ObservedObject var inboxNavModel = NavModel(startNavigated: false)
    @State var showingAuth = false
    @State var selected = Tab.Posts
    @State var showInvalidUser = false

    init(selectedTab: StartingTab) {
        self.selectedTab = selectedTab
    }

    var selectedNavModel: NavModel? {
        switch selected {
        case .Posts:
            return homeNavModel
        case .Accounts:
            return nil
        case .Search:
            return searchNavModel
        case .Inbox:
            return inboxNavModel
        case .Settings:
            return settingsNavModel
        }
    }

    var body: some View {
        ZStack {
            if !splashAccepted {
                SplashView()
            } else {
                VStack(spacing: 0) {
                    Group {
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                                .navigationViewStyle(.stack)
                            } else {
                                HomeView()
                                    .handleNavigations(navModel: homeNavModel)
                            }
                        }
                        .frame(maxWidth: selected == .Posts ? .infinity : 0, maxHeight: selected == .Posts ? .infinity : 0)
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                                .navigationViewStyle(.stack)
                            } else if apiModel.selectedAccount == nil {
                                NavigationView {
                                    AuthenticationView()
                                }
                            } else {
                                InboxView()
                                    .navigationTitle("Inbox")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .handleNavigations(navModel: inboxNavModel)
                            }
                        }
                        .frame(maxWidth: selected == .Inbox ? .infinity : 0, maxHeight: selected == .Inbox ? .infinity : 0)
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                                .navigationViewStyle(.stack)
                            } else if apiModel.selectedAccount == nil {
                                NavigationView {
                                    AuthenticationView()
                                }
                                .navigationViewStyle(.stack)
                            } else {
                                UserView(currentUser: true)
                                    .navigationTitle("Accounts")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .handleNavigations(navModel: userNavModel)
                            }
                        }
                        .frame(maxWidth: selected == .Accounts ? .infinity : 0, maxHeight: selected == .Accounts ? .infinity : 0)
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                                .navigationViewStyle(.stack)
                            } else {
                                SearchView()
                            }
                        }
                        .handleNavigations(navModel: searchNavModel)
                        .frame(maxWidth: selected == .Search ? .infinity : 0, maxHeight: selected == .Search ? .infinity : 0)
                        SettingsView()
                            .handleNavigations(navModel: settingsNavModel)
                            .frame(maxWidth: selected == .Settings ? .infinity : 0, maxHeight: selected == .Settings ? .infinity : 0)
                    }
                    HStack {
                        Button { setOrClear(.Posts) } label: { Label("Posts", systemImage: "doc.text.image") }
                            .foregroundStyle(selected == .Posts ? Color.accentColor : .secondary)
                        Button { setOrClear(.Inbox) } label: { Label("Inbox", systemImage: "envelope") }
                            .foregroundStyle(selected == .Inbox ? Color.accentColor : .secondary)
                            .if(apiModel.unreadCount != 0) { view in view.overlay(alignment: .topTrailing) {
                                ZStack {
                                    Circle()
                                        .fill(.red)
                                    Text(String(apiModel.unreadCount))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 20, height: 20)
                                .scaleEffect(0.8)
                                .padding(.trailing, 10)
                                .padding(.top, -10)
                            }}
                        Button { setOrClear(.Accounts) } label: { Label("Accounts", systemImage: "person.crop.circle") }
                            .foregroundStyle(selected == .Accounts ? Color.accentColor : .secondary)
                            .highPriorityGesture(LongPressGesture().onEnded { _ in
                                if !apiModel.accounts.isEmpty {
                                    withAnimation(.linear(duration: 0.1)) {
                                        apiModel.showingAuth.toggle()
                                    }
                                }
                            })
                        Button { setOrClear(.Search) } label: { Label("Search", systemImage: "magnifyingglass") }
                            .foregroundStyle(selected == .Search ? Color.accentColor : .secondary)
                        Button { setOrClear(.Settings) } label: { Label("Settings", systemImage: "gear") }
                            .foregroundStyle(selected == .Settings ? Color.accentColor : .secondary)
                    }
                    .padding(13)
                    .buttonStyle(.plain)
                    .labelStyle(TabLabelStyle())
                    .background(selectedTheme.backgroundColor)
                }
                .padding(.bottom, 10)
                .ignoresSafeArea()
                .onAppear {
                    if let requestedTab = selectedTab.requestedTab, let tab = Tab(rawValue: requestedTab) {
                        self.selected = tab
                        selectedTab.requestedTab = nil
                    }
                    if let requestedUrl = selectedTab.requestedUrl {
                        if requestedUrl.absoluteString.contains("post") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedNavModel!.path.append(ResolveModel<LemmyApi.PostView>(thing: requestedUrl))
                            }
                        } else if requestedUrl.absoluteString.contains("comment") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedNavModel!.path.append(ResolveModel<LemmyApi.CommentView>(thing: requestedUrl))
                            }
                        }
                        selectedTab.requestedUrl = nil
                    }
                }
                .onChange(of: selectedTab.requestedTab) { newValue in
                    if let requestedTab = newValue, let tab = Tab(rawValue: requestedTab) {
                        self.selected = tab
                        selectedTab.requestedTab = nil
                    }
                }
                .onChange(of: selectedTab.requestedUrl) { newValue in
                    if let requestedUrl = newValue {
                        if requestedUrl.absoluteString.contains("post") {
                            selectedNavModel!.path.append(ResolveModel<LemmyApi.PostView>(thing: requestedUrl))
                        } else if requestedUrl.absoluteString.contains("comment") {
                            selectedNavModel!.path.append(ResolveModel<LemmyApi.CommentView>(thing: requestedUrl))
                        }
                        selectedTab.requestedUrl = nil
                    }
                }
                .onOpenURL { incomingUrl in
                    var incomingUrl = incomingUrl
                    if let components = URLComponents(url: incomingUrl, resolvingAgainstBaseURL: false), let queryItems = components.queryItems, let first = queryItems.first, first.name == "url", let firstValue = first.value, let url = URL(string: firstValue) {
                        incomingUrl = url
                    }
                    if let host = incomingUrl.host(), let tab = Tab(rawValue: host) {
                        selected = tab
                    }
                    var selectedNavModel = selectedNavModel
                    if selectedNavModel == nil {
                        selectedNavModel = homeNavModel
                        selected = .Posts
                    }
                    if let match = incomingUrl.absoluteString.firstMatch(of: communityRegex) {
                        if let instance = match.3 {
                            selectedNavModel!.path.append(PostsModel(path: "\(match.2)\(instance)"))
                        } else {
                            selectedNavModel!.path.append(PostsModel(path: "\(match.2)@\(match.1)"))
                        }
                    } else if let match = incomingUrl.absoluteString.firstMatch(of: userRegex) {
                        if let instance = match.3 {
                            selectedNavModel!.path.append(UserModel(path: "\(match.2)\(instance)"))
                        } else {
                            selectedNavModel!.path.append(UserModel(path: "\(match.2)@\(match.1)"))
                        }
                    } else if incomingUrl.absoluteString.firstMatch(of: postRegex) != nil {
                        var urlComponents = URLComponents(url: incomingUrl, resolvingAgainstBaseURL: false)!
                        urlComponents.scheme = "https"
                        selectedNavModel!.path.append(ResolveModel<LemmyApi.PostView>(thing: urlComponents.url!))
                    } else if incomingUrl.absoluteString.firstMatch(of: commentRegex) != nil {
                        var urlComponents = URLComponents(url: incomingUrl, resolvingAgainstBaseURL: false)!
                        urlComponents.scheme = "https"
                        selectedNavModel!.path.append(ResolveModel<LemmyApi.CommentView>(thing: urlComponents.url!))
                    }
                }
                .toast(isPresenting: $showInvalidUser) {
                    AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Invalid token, please relogin.")
                } completion: {
                    apiModel.invalidUser = nil
                }
                .onChange(of: apiModel.invalidUser) { newValue in
                    if newValue != nil {
                        self.showInvalidUser = true
                    }
                }
                .popupNavigationView(isPresented: $apiModel.showingAuth, heightRatio: 1.5, widthRatio: 1.1) {
                    AuthenticationView()
                }
                .environmentObject(apiModel)
                // Hack to cause update
                .navigationBarModifier(theme: pureBlack ? selectedTheme : selectedTheme)
                .environment(\.colorScheme, colorScheme == .System ? systemColorScheme : colorScheme == .Dark ? .dark : .light)
            }
        }
        .environment(\.dynamicTypeSize, systemFont ? size : DynamicTypeSize.allCases[Int(fontSize)])
    }

    func setOrClear(_ target: Tab) {
        if selected == target {
            selectedNavModel?.clear()
        } else {
            selected = target
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

extension URL: Identifiable {
    public var id: URL { self }
}

enum Tab: String {
    case Posts, Inbox, Accounts, Search, Settings
}

struct TabLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .scaleEffect(1.25)
            configuration.title
        }
        .frame(maxWidth: .infinity)
    }
}
