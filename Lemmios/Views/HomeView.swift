import SwiftUI

struct HomeView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @EnvironmentObject var apiModel: ApiModel
    @State var homeShowing = true

    var body: some View {
        ZStack {
            ColoredListComponent {
                HStack {
                    Image(systemName: "arrow.up")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(3)
                        .background(.red)
                        .clipShape(Circle())
                        .frame(width: 24, height: 24)
                    NavigationLink("All", value: PostsModel(path: "All"))
                }
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(3)
                        .background(.blue)
                        .clipShape(Circle())
                        .frame(width: 24, height: 24)
                    NavigationLink("Local", value: PostsModel(path: "Local"))
                }
                if let subscribed = apiModel.subscribed {
                    HStack {
                        Image(systemName: "house")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(3)
                            .background(.green)
                            .clipShape(Circle())
                            .frame(width: 24, height: 24)
                        NavigationLink("Home", value: PostsModel(path: "Subscribed"))
                    }
                    ForEach(subscribed.keys.sorted(), id: \.self) { firstLetter in
                        Section {
                            ForEach(subscribed[firstLetter]!) { community in
                                CommunityLink(community: community, showPlaceholder: true, prefix: {}, suffix: {})
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
