import SwiftUI

struct HomeView: View {
    @EnvironmentObject var apiModel: ApiModel
    @State var homeShowing = true
//    @State private var path = NavigationPath()
    var body: some View {
        NavigationStack {
            Button("Home") {
                homeShowing = true
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $homeShowing) {
                PostsView(postsModel: PostsModel(apiModel: apiModel, path: "Home"))
            }            
        }
    }
}
