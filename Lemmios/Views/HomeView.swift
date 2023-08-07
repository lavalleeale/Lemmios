import LemmyApi
import SwiftUI

struct HomeView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @EnvironmentObject var apiModel: ApiModel
    @State var homeShowing = true
    @State var searchText = ""

    var body: some View {
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
            if let subscribedArray = apiModel.subscribed?.map({ (key: String, value: [LemmyApi.Community]) in
                (key, value.filter { searchText == "" || $0.name.lowercased().contains(searchText.lowercased()) })
            }).filter({ !$0.1.isEmpty }) {
                let subscribed = Dictionary(uniqueKeysWithValues: subscribedArray)
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
                            let model = PostsModel(path: "\(community.name)\(community.local ? "" : "@\(community.actor_id.host()!)")")
                            NavigationLink(value: model) {
                                ShowFromComponent(item: community, show: true)
                            }
                        }
                    } header: {
                        Text(firstLetter)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}
