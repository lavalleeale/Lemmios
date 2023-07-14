import AlertToast
import SafariServices
import SwiftUI
import ImageViewer

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

    let communityRegex = /^lemmiosapp:\/\/(.+?)\/c\/([a-z_]+)(@[a-z\-.]+)?$/
    let userRegex = /^lemmiosapp:\/\/(.+?)\/u\/([a-zA-Z_]+)(@[a-z\-.]+)?$/

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
                TabView(selection: Binding(get: { self.selected }, set: {
                    if $0 == selected {
                        if let selectedNavModel = selectedNavModel {
                            selectedNavModel.clear()
                        } else {
                            if !apiModel.accounts.isEmpty {
                                withAnimation(.linear(duration: 0.1)) {
                                    apiModel.showingAuth.toggle()
                                }
                            }
                        }
                    }
                    self.selected = $0
                })) {
                    Group {
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                            } else {
                                HomeView()
                                    .handleNavigations(navModel: homeNavModel)
                            }
                        }
                        .tabItem {
                            Label("Posts", systemImage: "doc.text.image")
                        }
                        .tag(Tab.Posts)
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
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
                        .tabItem {
                            Label("Inbox", systemImage: "envelope")
                        }
                        .badge(apiModel.unreadCount)
                        .tag(Tab.Inbox)
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                            } else if apiModel.selectedAccount == nil {
                                NavigationView {
                                    AuthenticationView()
                                }
                            } else {
                                UserView(currentUser: true)
                                    .navigationTitle("Accounts")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .handleNavigations(navModel: userNavModel)
                            }
                        }
                        .tabItem {
                            Label("Accounts", systemImage: "person.crop.circle")
                        }
                        .tag(Tab.Accounts)
                        ZStack {
                            if !apiModel.serverSelected {
                                NavigationView {
                                    ServerSelectorView()
                                }
                            } else {
                                SearchView()
                            }
                        }
                        .handleNavigations(navModel: searchNavModel)
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(Tab.Search)
                        SettingsView()
                            .handleNavigations(navModel: settingsNavModel)
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                            .tag(Tab.Settings)
                    }
                    .toolbarBackground(selectedTheme.backgroundColor, for: .tabBar)
                    .toolbar(.visible, for: .tabBar)
                }
                .onAppear {
                    if let requestedTab = selectedTab.requestedTab, let tab = Tab(rawValue: requestedTab) {
                        self.selected = tab
                        selectedTab.requestedTab = nil
                    }
                }
                .onChange(of: selectedTab.requestedTab) { newValue in
                    if let requestedTab = newValue, let tab = Tab(rawValue: requestedTab) {
                        self.selected = tab
                        selectedTab.requestedTab = nil
                    }
                }
                .onOpenURL { incomingUrl in
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
                    }
                }
                .toast(isPresenting: $showInvalidUser) {
                    AlertToast(displayMode: .alert, type: .error(.red), title: "Invalid token, please relogin.")
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
