import AlertToast
import SwiftUI
import UIKit

let specialPostPathList = ["All", "Subscribed"]

struct PostsView: View {
    @ObservedObject var postsModel: PostsModel
    @ObservedObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @State var newPath: String = ""
    @State var showingCreate = false
    @State private var id = UUID().uuidString
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        let isSpecialPath = specialPostPathList.contains(postsModel.path)
        ZStack {
            if apiModel.serverSelected {
                List {
                    ForEach(postsModel.posts) { post in
                        VStack {
                            PostPreviewComponent(post: post, showCommunity: isSpecialPath, showUser: !isSpecialPath)
                                .onAppear {
                                    if postsModel.posts.count > 0 && post.id == postsModel.posts.last?.id {
                                        postsModel.fetchPosts(apiModel: apiModel)
                                    }
                                }
                                .padding(.horizontal, 10)
                            Rectangle()
                                .fill(.secondary.opacity(0.1))
                                .frame(height: 10)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                    }
                    if case .failed = postsModel.pageStatus {
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
                .onChange(of: apiModel.selectedAccount) { _ in
                    self.id = UUID().uuidString
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
        .id(id)
        .navigationBarTitle((postsModel.path != "") ? postsModel.path : "All", displayMode: .inline)
        .overlay(alignment: .top) {
            if let communities = searchedModel.communities?.filter({ $0.community.name.contains(newPath.lowercased()) }).prefix(5), communities.count != 0 {
                List(communities) { community in
                    let communityHost = community.community.actor_id.host()!
                    let apiHost = URL(string: apiModel.url)!.host()!
                    NavigationLink(
                    ) {} label: {
                        ShowFromComponent(item: community.community)
                    }
                    .onTapGesture {
                        navModel.path.append(PostsModel(
                            path: apiHost == communityHost ? community.community.name : "\(community.community.name)@\(communityHost)"))
                    }
                    .buttonStyle(.plain)
                }
                .onTapGesture {
                    withAnimation(.linear(duration: 0.1)) {
                        newPath = ""
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .scrollContentBackground(.hidden)
                .backgroundStyle(.clear)
            }
        }
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
                            showingCreate.toggle()
                        } label: {
                            Label("Submit Post", systemImage: "plus")
                        }
                        Button {
                            if apiModel.selectedAccount == "" {
                                apiModel.getAuth()
                            } else {
                                postsModel.follow(apiModel: apiModel)
                            }
                        } label: {
                            Label(postsModel.communityView?.community_view.subscribed != "NotSubscribed" ? "Unfollow" : "Follow", systemImage: postsModel.communityView?.community_view.subscribed != "NotSubscribed" ? "heart.slash" : "heart")
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
