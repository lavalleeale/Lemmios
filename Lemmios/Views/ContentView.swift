import SafariServices
import SwiftUI

struct ContentView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("colorScheme") var colorScheme = ColorScheme.System
    @AppStorage("pureBlack") var pureBlack = false
    @Environment(\.colorScheme) var systemColorScheme
    
    @ObservedObject var apiModel = ApiModel()
    @ObservedObject var homeNavModel = NavModel(startNavigated: true)
    @ObservedObject var searchNavModel = NavModel(startNavigated: false)
    @ObservedObject var userNavModel = NavModel(startNavigated: false)
    @ObservedObject var settingsNavModel = NavModel(startNavigated: false)
    @ObservedObject var inboxNavModel = NavModel(startNavigated: false)
    @ObservedObject var searchModel = SearchModel()
    @ObservedObject var userModel = UserModel(path: "")
    @ObservedObject var inboxModel = InboxModel()
    @State var showingAuth = false
    @State var selected = Tab.Posts
    
    let communityRegex = /^lemmiosapp:\/\/(.+?)\/c\/([a-z_]+)(@[a-z\-.]+)?$/
    let userRegex = /^lemmiosapp:\/\/(.+?)\/u\/([a-zA-Z_]+)(@[a-z\-.]+)?$/

    init() {
        if apiModel.serverSelected {
            self.userModel = UserModel(path: "\(apiModel.selectedAccount)@\(URL(string: apiModel.url)!.host()!)")
        }
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
        TabView(selection: Binding(get: { self.selected }, set: {
            if $0 == selected {
                if let selectedNavModel = selectedNavModel {
                    selectedNavModel.clear()
                } else {
                    if apiModel.selectedAccount != "" {
                        withAnimation(.linear(duration: 0.1)) {
                            apiModel.showingAuth.toggle()
                        }
                    }
                }
            }
            self.selected = $0
        })) {
            Group {
                HomeView()
                    .handleNavigations(navModel: homeNavModel)
                    .tabItem {
                        Label("Posts", systemImage: "doc.text.image")
                    }
                    .tag(Tab.Posts)
                InboxView(inboxModel: inboxModel)
                    .navigationTitle("Inbox")
                    .navigationBarTitleDisplayMode(.inline)
                    .handleNavigations(navModel: inboxNavModel)
                    .tabItem {
                        Label("Inbox", systemImage: "envelope")
                    }
                    .badge(apiModel.unreadCount)
                    .tag(Tab.Inbox)
                ZStack {
                    if !apiModel.serverSelected {
                        ServerSelectorView()
                    } else if apiModel.selectedAccount == "" {
                        AuthenticationView()
                    } else {
                        UserView(userModel: userModel)
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
                        ServerSelectorView()
                    } else {
                        SearchView(searchModel: searchModel)
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
        .onOpenURL { incomingUrl in
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
        .onChange(of: apiModel.selectedAccount) { newValue in
            userModel.name = "\(newValue)@\(URL(string: apiModel.url)!.host()!)"
            userModel.reset()
            inboxModel.reset()
        }
        .alert("Subscribe to c/lemmiosapp?", isPresented: $apiModel.showingSubscribe) {
            Button("No") {}
            Button("Yes") {
                apiModel.followSelf()
            }
        } message: {
            Text("The official subreddit for this app! Subscribe to the community for news on the app, feature requests, and more!")
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

enum Tab {
    case Posts, Inbox, Accounts, Search, Settings
}
