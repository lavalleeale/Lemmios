import SwiftUI

struct SearchedView: View {
    @ObservedObject var searchedModel: SearchedModel
    @EnvironmentObject var apiModel: ApiModel
    var body: some View {
        ZStack {
            if let communities = searchedModel.communities {
                ColoredListComponent {
                    ForEach(communities) { community in
                        let communityHost = community.community.actor_id.host()!
                        let apiHost = URL(string: apiModel.url)!.host()!
                        NavigationLink(value: PostsModel(
                            path: apiHost == communityHost ? community.community.name : "\(community.community.name)@\(communityHost)")
                        ) {
                            ShowFromComponent(item: community.community)
                                .onAppear {
                                    if community.id == communities.last!.id {
                                        searchedModel.fetchCommunties(apiModel: apiModel)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onFirstAppear {
                    searchedModel.fetchCommunties(apiModel: apiModel)
                }
            } else if let posts = searchedModel.posts {
                ColoredListComponent {
                    ForEach(posts) { post in
                        PostPreviewComponent(post: post, showCommunity: true, showUser: false)
                            .onAppear {
                                if post.id == posts.last!.id {
                                    searchedModel.fetchPosts(apiModel: apiModel)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .onFirstAppear {
                    searchedModel.fetchPosts(apiModel: apiModel)
                }
            } else if let users = searchedModel.users {
                ColoredListComponent {
                    ForEach(users) { user in
                        NavigationLink(value: UserModel(user: user.person)) {
                            ShowFromComponent(item: user.person)
                                .onAppear {
                                    if user.id == users.last!.id {
                                        searchedModel.fetchUsers(apiModel: apiModel)
                                    }
                                }
                        }
                    }
                }
                .onFirstAppear {
                    searchedModel.fetchUsers(apiModel: apiModel)
                }
            }
        }
        .navigationTitle("\"\(searchedModel.query)\"")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SortSelectorComponent(sortType: .Search, currentSort: $searchedModel.sort, currentTime: $searchedModel.time) { sort, time in
                    searchedModel.changeSortAndTime(sort: sort, time: time, apiModel: apiModel)
                }
            }
        }
    }
}
