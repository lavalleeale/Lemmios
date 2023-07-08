import SwiftUI

struct HomeView: View {
    @EnvironmentObject var apiModel: ApiModel
    @State var homeShowing = true
    
    var body: some View {
        ZStack {
            if apiModel.serverSelected {
                let apiHost = URL(string: apiModel.url)!.host()!
                List {
                    NavigationLink("All", value: PostsModel(path: "All"))
                    if let subscribed = apiModel.subscribed {
                        NavigationLink("Home", value: PostsModel(path: "Subscribed"))
                        ForEach(subscribed.keys.sorted(), id: \.self) { firstLetter in
                            Section {
                                ForEach(subscribed[firstLetter]!) { community in
                                    let communityHost = community.actor_id.host()!
                                    NavigationLink(value: PostsModel(path: communityHost == apiHost ? community.name : "\(community.name)@\(communityHost)")) {
                                        ShowFromComponent(item: community)
                                    }
                                }
                            } header: {
                                Text(firstLetter)
                            }
                        }
                    }
                }
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ServerSelectorView()
            }
        }
    }
}
