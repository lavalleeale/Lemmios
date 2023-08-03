import AlertToast
import SwiftUI
import UIKit

let specialPostPathList = ["All", "Subscribed", "Local"]

struct PostsView: View {
    @ObservedObject var postsModel: PostsModel
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @State var showingCreate = false
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        let isSpecialPath = specialPostPathList.contains(postsModel.path)
        ColoredListComponent {
            ForEach(0 ..< postsModel.posts.count * 2, id: \.self) { post in
                Group {
                    if post % 2 == 0 {
                        let post = postsModel.posts[post / 2]
                        PostPreviewComponent(post: post, showCommunity: isSpecialPath, showUser: !isSpecialPath)
                            .onAppear {
                                if postsModel.posts.count > 0 && post.id == postsModel.posts.last?.id {
                                    postsModel.fetchPosts(apiModel: apiModel)
                                }
                            }
                    } else {
                        Rectangle()
                            .fill(.secondary.opacity(0.1))
                            .frame(height: 10)
                    }
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
                    if postsModel.skipped != 0 {
                        Text("Loaded and skipped \(postsModel.skipped) read posts")
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .environment(\.defaultMinListRowHeight, 10)
        .coordinateSpace(name: "posts")
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
            if let communities = searchedModel.communities?.filter({ $0.community.name.lowercased().contains(searchedModel.query.lowercased()) }).prefix(5), communities.count != 0 {
                ColoredListComponent(customBackground: .black.opacity(0.25)) {
                    CommmunityListComponent(communities: communities)
                }
                .onTapGesture {
                    withAnimation(.linear(duration: 0.1)) {
                        searchedModel.query = ""
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .toast(isPresenting: $searchedModel.rateLimited) {
            AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Search rate limit reached")
        }
        .onChange(of: apiModel.selectedAccount) { _ in
            postsModel.refresh(apiModel: apiModel)
        }
        .onReceive(searchedModel.$query.throttle(for: 1, scheduler: RunLoop.main, latest: true)) { newValue in
            self.searchedModel.reset(removeResults: false)
            if newValue != "" {
                self.searchedModel.query = newValue
                self.searchedModel.fetchCommunties(apiModel: apiModel, reset: true)
            }
        }
        .onAppear {
            searchedModel.query = ""
        }
        .toast(isPresenting: $postsModel.postCreated, duration: 3) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: "Posted! Tap to view.")
        } onTap: {
            navModel.path.append(PostModel(post: postsModel.createdPost!))
        }
        .navigationBarTitle((postsModel.path != "") ? postsModel.path : "All", displayMode: .inline)
        .toolbar(content: { navigationBar })
        .sheet(isPresented: $showingCreate) {
            PostCreateComponent(dataModel: postsModel)
        }
    }

    var navigationBar: some ToolbarContent {
        Group {
            let isSpecialPath = specialPostPathList.contains(postsModel.path)
            ToolbarItem(placement: .principal) {
                TextField((postsModel.path == "") ? "All" : postsModel.path, text: $searchedModel.query, onCommit: {
                    navModel.path.append(PostsModel(path: searchedModel.query))
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
                        if let communityView = postsModel.communityView {
                            PostButton(label: "Share", image: "square.and.arrow.up") {
                                alwaysShare(item: communityView.community_view.community.actor_id)
                            }
                        }
                        PostButton(label: "Submit Post", image: "plus") {
                            showingCreate.toggle()
                        }
                        let subscribed = postsModel.communityView?.community_view.subscribed != "NotSubscribed"
                        PostButton(label: subscribed ? "Unfollow" : "Follow", image: subscribed ? "heart.slash" : "heart") {
                            postsModel.follow(apiModel: apiModel)
                        }
                        let blocked = postsModel.communityView?.community_view.blocked == true
                        PostButton(label: blocked ? "Unblock" : "Block", image: "x.circle") {
                            postsModel.block(apiModel: apiModel, block: !blocked)
                        }
                        if let communityId = postsModel.communityView?.community_view.id {
                            PostButton(label: "Modlog", image: "shield") {
                                navModel.path.append(ModlogModel(communityId: communityId))
                            }
                            .tint(.green)
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
        }
    }
}
