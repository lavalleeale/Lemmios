import SafariServices
import SwiftUI

struct ContentView: View {
    @ObservedObject var apiModel = ApiModel()
    @ObservedObject var homeNavModel = NavModel(startNavigated: true)
    @ObservedObject var searchNavModel = NavModel(startNavigated: false)
    @ObservedObject var userNavModel = NavModel(startNavigated: false)
    @ObservedObject var searchModel = SearchModel()
    @ObservedObject var userModel = UserModel(path: "")
    @State var showingAuth = false
    @State var selected = "Posts"
    
    init() {
        self.userModel.name = self.apiModel.selectedAccount
    }

    var body: some View {
        TabView(selection: Binding(get: { self.selected }, set: {
            if $0 == "Auth", selected == "Auth" {
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
                    UserView(userModel: userModel)
                        .handleNavigations(navModel: userNavModel)
                }
            }
            .tabItem {
                Label("Accounts", systemImage: "person.crop.circle")
            }
            .tag("Auth")
            SearchView(searchModel: searchModel)
                .handleNavigations(navModel: searchNavModel)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag("Search")
            SettingsView()
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
            self.userModel.name = "\(newValue)@\(URL(string: apiModel.url)!.host()!)"
        }
        .popupNavigationView(isPresented: $showingAuth) {
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
