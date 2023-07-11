import SwiftUI

struct HomeView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @EnvironmentObject var apiModel: ApiModel
    @State var homeShowing = true

    var body: some View {
        ZStack {
            ColoredListComponent {
                NavigationLink("All", value: PostsModel(path: "All"))
                NavigationLink("Local", value: PostsModel(path: "Local"))
                if let subscribed = apiModel.subscribed {
                    NavigationLink("Home", value: PostsModel(path: "Subscribed"))
                    ForEach(subscribed.keys.sorted(), id: \.self) { firstLetter in
                        Section {
                            ForEach(subscribed[firstLetter]!) { community in
                                if community.local {
                                    NavigationLink(value: PostsModel(path: community.name)) {
                                        ShowFromComponent(item: community)
                                    }
                                } else {
                                    let communityHost = community.actor_id.host()!
                                    NavigationLink(value: PostsModel(path: "\(community.name)@\(communityHost)")) {
                                        ShowFromComponent(item: community)
                                    }
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
        }
    }
}
