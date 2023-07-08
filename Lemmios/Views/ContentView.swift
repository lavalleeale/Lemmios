import SafariServices
import SwiftUI

struct ContentView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @ObservedObject var apiModel = ApiModel()
    @ObservedObject var homeNavModel = NavModel(startNavigated: true)
    @ObservedObject var searchNavModel = NavModel(startNavigated: false)
    @ObservedObject var userNavModel = NavModel(startNavigated: false)
    @ObservedObject var settingsNavModel = NavModel(startNavigated: false)
    @ObservedObject var searchModel = SearchModel()
    @ObservedObject var userModel = UserModel(path: "")
    @State var showingAuth = false
    @State var selected = "Posts"

    init() {
        if apiModel.serverSelected {
            self.userModel = UserModel(path: "\(apiModel.selectedAccount)@\(URL(string: apiModel.url)!.host()!)")
        }
    }

    var body: some View {
        ZStack {
            Color.yellow.opacity(0.1).onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            TabView(selection: Binding(get: { self.selected }, set: {
                if $0 == selected {
                    switch selected {
                    case "Posts":
                        homeNavModel.clear()
                    case "Auth":
                        if apiModel.selectedAccount != "" {
                            withAnimation(.linear(duration: 0.1)) {
                                apiModel.showingAuth.toggle()
                            }
                        }
                    case "Search":
                        searchNavModel.clear()
                    default:
                        settingsNavModel.clear()
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
                        .tag("Posts")
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
                    .tag("Auth")
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
                    .tag("Search")
                    SettingsView()
                        .handleNavigations(navModel: settingsNavModel)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag("Settings")
                }
                .toolbarBackground(selectedTheme.backgroundColor, for: .tabBar)
                .toolbar(.visible, for: .tabBar)
            }
            .onChange(of: apiModel.selectedAccount) { newValue in
                userModel.name = "\(newValue)@\(URL(string: apiModel.url)!.host()!)"
                userModel.reset()
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
            .navigationBarModifier(backgroundColor: UIColor(selectedTheme.backgroundColor))
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
