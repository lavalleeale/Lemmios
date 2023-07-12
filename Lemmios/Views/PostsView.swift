import AlertToast
import SwiftUI
import UIKit

let specialPostPathList = ["All", "Subscribed", "Local"]

struct PostsView: View {
    @ObservedObject var postsModel: PostsModel
    @ObservedObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @State var newPath: String = ""
    @State var showingCreate = false
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        let isSpecialPath = specialPostPathList.contains(postsModel.path)
        ZStack {
            if apiModel.serverSelected {
                ColoredListComponent {
                    ForEach(postsModel.posts) { post in
                        VStack {
                            PostPreviewComponent(post: post, showCommunity: isSpecialPath, showUser: !isSpecialPath)
                                .onAppear {
                                    if postsModel.posts.count > 0 && post.id == postsModel.posts.last?.id {
                                        postsModel.fetchPosts(apiModel: apiModel)
                                    }
                                }
                            Rectangle()
                                .fill(.secondary.opacity(0.1))
                                .frame(height: 10)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                    }
                    if postsModel.notFound {
                        Text("Community not found.")
                    } else if case .failed = postsModel.pageStatus {
                        HStack {
                            Text("Lemmy Request Failed, ")
                            Button("refresh?") {
                                postsModel.refresh(apiModel: apiModel)
                            }
                        }
                        .listRowSeparator(.hidden)
                    } else if case .done = postsModel.pageStatus {
                        Text("Last Post Found ):")
                            .listRowSeparator(.hidden)
                    } else if case .loading = postsModel.pageStatus {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    withAnimation {
                        postsModel.refresh(apiModel: apiModel)
                    }
                }
                .onAppear {
                    postsModel.fetchPosts(apiModel: apiModel)
                }
                .overlay {
                    if let communities = searchedModel.communities?.filter({ $0.community.name.contains(newPath.lowercased()) }).prefix(5), communities.count != 0 {
                        ColoredListComponent(customBackground: .black.opacity(0.25)) {
                            CommmunityListComponent(communities: communities)
                        }
                        .onTapGesture {
                            withAnimation(.linear(duration: 0.1)) {
                                newPath = ""
                            }
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            } else {
                ServerSelectorView()
            }
        }
        .onChange(of: apiModel.selectedAccount) { _ in
            postsModel.refresh(apiModel: apiModel)
        }
        .onChange(of: newPath) { newValue in
            self.searchedModel.reset(removeResults: false)
            if newValue != "" {
                self.searchedModel.query = newValue
                self.searchedModel.fetchCommunties(apiModel: apiModel, reset: true)
            }
        }
        .onAppear {
            newPath = ""
        }
        .toast(isPresenting: $postsModel.postCreated, duration: 3) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Posted! Tap to view.")
        } onTap: {
            navModel.path.append(PostModel(post: postsModel.createdPost!))
        }
        .navigationBarTitle((postsModel.path != "") ? postsModel.path : "All", displayMode: .inline)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                TextField((postsModel.path == "") ? "All" : postsModel.path, text: $newPath, onCommit: {
                    navModel.path.append(PostsModel(path: newPath))
                })
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.center)
                .frame(width: 100)
                .textFieldStyle(PlainTextFieldStyle())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                SortSelectorComponent(sortType: .Posts, currentSort: $postsModel.sort, currentTime: $postsModel.time) { sort, time in
                    postsModel.changeSortAndTime(sort: sort, time: time, apiModel: apiModel)
                }
            }
            if !isSpecialPath {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                showingCreate.toggle()
                            }
                        } label: {
                            Label("Submit Post", systemImage: "plus")
                        }
                        Button {
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                postsModel.follow(apiModel: apiModel)
                            }
                        } label: {
                            let subscribed = postsModel.communityView?.community_view.subscribed != "NotSubscribed"
                            Label(subscribed ? "Unfollow" : "Follow", systemImage: subscribed ? "heart.slash" : "heart")
                        }
                        let blocked = postsModel.communityView?.community_view.blocked == true
                        Button {
                            postsModel.block(apiModel: apiModel, block: !blocked)
                        } label: {
                            Label(blocked ? "Unblock" :  "Block", systemImage: "x.circle")
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
            }
        })
        .sheet(isPresented: $showingCreate) {
            PostCreateComponent(postsModel: postsModel)
        }
    }
}
