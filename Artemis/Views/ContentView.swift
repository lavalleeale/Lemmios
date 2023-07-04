import SwiftUI

struct ContentView: View {
    @ObservedObject var apiModel = ApiModel()
    @State var showingAuth = false
    @State var selected = "Posts"

    var body: some View {
        TabView(selection: $selected) {
                HomeView()
//                PostsView(postsModel: PostsModel(apiModel: apiModel, path: "artemistesting"))
            .tabItem {
                Label("Posts", systemImage: "doc.text.image")
            }
            .tag("Posts")
            Text("You Should Never see this")
                .onAppear {
                    self.selected = "Posts"
                    showingAuth.toggle()
                }
                .tabItem {
                    Label("Accounts", systemImage: "person.crop.circle")
                }
                .tag("Auth")
        }
        .onAppear {
            apiModel.setShowAuth {
                showingAuth.toggle()
            }
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .environmentObject(apiModel)
    }
}
