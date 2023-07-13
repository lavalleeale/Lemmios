import SwiftUI

struct UserView: View {
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var userModel = UserModel(path: "")
    @State var selectedTab = UserViewTab.Overview
    @State var currentUser = false
    @State var showMessage = false
    @State var showingAccounts = false
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
                            if let account = apiModel.selectedAccount, let userData = userModel.userData, !tab.onlyShowInOwnProfile || userData.person == account {
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
                .toolbar {
                    if let userData = userModel.userData, let account = apiModel.selectedAccount {
                        if userData.person != account {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu {
                                    Button {
                                        showMessage = true
                                    } label: {
                                        Label("Message", systemImage: "arrowshape.turn.up.left")
                                    }
                                    let blocked = userModel.blocked
                                    Button {
                                        if apiModel.selectedAccount == nil {
                                            apiModel.getAuth()
                                        } else {
                                            userModel.block(apiModel: apiModel, block: !blocked)
                                        }
                                    } label: {
                                        Label(blocked ? "Unblock" : "Block", systemImage: "x.circle")
                                    }
                                } label: {
                                    VStack {
                                        Spacer()
                                        Label("More Options", systemImage: "ellipsis")
                                            .labelStyle(.iconOnly)
                                        Spacer()
                                    }
                                }
                            }
                        } else {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Accounts") {
                                    showingAccounts = true
                                }
                                .popupNavigationView(isPresented: $showingAccounts, heightRatio: 1.5, widthRatio: 1.1) {
                                    AuthenticationView()
                                }
                            }
                        }
                    }
                }
            } else {
                Text("This should never be seen")
            }
        }
        .onAppear {
            if currentUser {
                userModel.name = apiModel.selectedAccount?.username ?? ""
                userModel.reset()
            }
        }
        .onChange(of: apiModel.selectedAccount) { newValue in
            self.showingAccounts = false
            if currentUser {
                userModel.name = newValue?.username ?? ""
                userModel.reset()
            }
        }
        .sheet(isPresented: $showMessage) {
            CommentSheet(title: "Send Message") { commentBody in
                userModel.message(content: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
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
