import SwiftUI

struct UserView: View {
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var userModel = UserModel(path: "")
    @State var selectedTab = UserViewTab.Overview
    var body: some View {
        Group {
            let split = userModel.name.split(separator: "@")
            if let name = split.first {
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
                    if case .failed = userModel.pageStatus {
                        HStack {
                            Text("Lemmy Request Failed, ")
                            Button("refresh?") {
                                userModel.reset()
                                userModel.fetchData(apiModel: apiModel, saved: selectedTab == UserViewTab.Saved)
                            }
                        }
                        .listRowSeparator(.hidden)
                    } else if case .done = userModel.pageStatus {
                        Text("Last Item Found ):")
                            .listRowSeparator(.hidden)
                    } else if case .loading = userModel.pageStatus {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .refreshable {
                    userModel.reset()
                    userModel.fetchData(apiModel: apiModel, saved: selectedTab == UserViewTab.Saved)
                }
                .listStyle(.plain)
                .navigationTitle(userModel.userData?.person.local == true ? String(name) : userModel.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("This should never be seen")
            }
        }.onAppear {
            userModel.name = apiModel.selectedAccount
            userModel.reset()
        }
        .onChange(of: apiModel.selectedAccount) { newValue in
            userModel.name = newValue
            userModel.reset()
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
