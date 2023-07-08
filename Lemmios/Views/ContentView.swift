import SafariServices
import SwiftUI

struct ContentView: View {
    @ObservedObject var apiModel = ApiModel()
    @ObservedObject var homeNavModel = NavModel(startNavigated: true)
    @ObservedObject var searchNavModel = NavModel(startNavigated: false)
    @ObservedObject var userNavModel = NavModel(startNavigated: false)
    @ObservedObject var settingsNavModel = NavModel(startNavigated: false)
    @ObservedObject var searchModel = SearchModel()
    @State var showingAuth = false
    @State var selected = "Posts"

    init() {
        if apiModel.serverSelected {
            userNavModel.path.append(UserModel(path: "\(apiModel.selectedAccount)@\(URL(string: apiModel.url)!.host()!)"))
        }
    }

    var body: some View {
        TabView(selection: Binding(get: { self.selected }, set: {
            if $0 == "Auth", selected == "Auth", apiModel.selectedAccount != "" {
                withAnimation(.linear(duration: 0.1)) {
                    showingAuth.toggle()
                }
            }
            self.selected = $0
        })) {
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
                    List(apiModel.accounts) { account in
                        NavigationLink(account.username, value: UserModel(path: "\(account.username)@\(URL(string: apiModel.url)!.host()!)"))
                    }
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
        .onFirstAppear {
            apiModel.setShowAuth {
                withAnimation(.linear(duration: 0.1)) {
                    showingAuth.toggle()
                }
            }
        }
        .onChange(of: apiModel.selectedAccount) { newValue in
            userNavModel.path.removeLast(userNavModel.path.count)
            userNavModel.path.append(UserModel(path: "\(newValue)@\(URL(string: apiModel.url)!.host()!)"))
        }
        .popupNavigationView(isPresented: $showingAuth, heightRatio: 1.5, widthRatio: 1.1) {
            AuthenticationView()
        }
        .environmentObject(apiModel)
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
