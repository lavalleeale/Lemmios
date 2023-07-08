import SwiftUI

struct UserView: View {
    @EnvironmentObject var apiModel: ApiModel
    @ObservedObject var userModel: UserModel
    @State var selectedTab = UserViewTab.Overview
    var body: some View {
        let apiHost = URL(string: apiModel.url)!.host()!
        let split = userModel.name.split(separator: "@")
        if let name = split.first, let from = split.last {
            ColoredListComponent {
                UserHeaderComponent(person_view: userModel.userData)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                // List separators don't work with infiinite width
                Divider()
                    .listRowSeparator(.hidden)
                Picker(selection: $selectedTab, label: Text("Profile Section")) {
                    ForEach(UserViewTab.allCases, id: \.id) { tab in
                        // Skip tabs that are meant for only our profile
                        if !tab.onlyShowInOwnProfile || name == apiModel.selectedAccount {
                            Text(tab.rawValue)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                switch selectedTab {
                case .Overview:
                    MixedListComponent(withCounts: userModel.posts + userModel.comments) {
                        userModel.fetchData(apiModel: apiModel)
                    }
                case .Comments:
                    MixedListComponent(withCounts: userModel.comments) {
                        userModel.fetchData(apiModel: apiModel)
                    }
                case .Posts:
                    MixedListComponent(withCounts: userModel.posts) {
                        userModel.fetchData(apiModel: apiModel)
                    }
                case .Saved:
                    MixedListComponent(withCounts: userModel.saved) {
                        userModel.fetchData(apiModel: apiModel, saved: true)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(from == apiHost ? String(name) : userModel.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("This should never be seen")
        }
    }
}

enum UserViewTab: String, CaseIterable, Identifiable {
    case Overview, Posts, Comments, Saved

    var id: Self { self }

    var onlyShowInOwnProfile: Bool {
        return self == UserViewTab.Saved
    }
}
