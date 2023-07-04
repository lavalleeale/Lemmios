import SwiftUI

struct PostsView: View {
    @EnvironmentObject var apiModel: ApiModel
    @ObservedObject var postsModel: PostsModel
    @State var newPath: String = ""
    @State var showingNew = false
    @State private var id = UUID().uuidString

    var body: some View {
        ZStack {
            if apiModel.serverSelected {
                List {
                    ForEach(postsModel.posts) { post in
                        PostPreviewComponent(post: post, showCommunity: postsModel.path == "Home", showUser: postsModel.path != "Home")
                            .onAppear {
                                if postsModel.posts.count > 0 && post.id == postsModel.posts.last?.id {
                                    postsModel.fetchPosts()
                                }
                            }
                    }
                    if case .failed = postsModel.pageStatus {
                        HStack {
                            Text("Lemmy Request Failed, ")
                            Button("refresh?") {
                                postsModel.refresh()
                            }
                        }
                    } else if case .done = postsModel.pageStatus {
                        HStack {
                            Text("Last Post Found ):")
                        }
                    }
                }
                .onChange(of: apiModel.selectedAccount) { _ in
                    self.id = UUID().uuidString
                }
                .listStyle(.plain)
                .refreshable {
                    withAnimation {
                        postsModel.refresh()
                    }
                }
                .onAppear {
                    postsModel.fetchPosts()
                }
            } else {
                ServerSelectorView()
            }
        }
        .onChange(of: apiModel.selectedAccount) { _ in
            postsModel.refresh()
        }
        .onAppear {
            newPath = ""
        }
        .id(id)
        .navigationBarTitle((postsModel.path != "") ? postsModel.path : "Home", displayMode: .inline)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                TextField((postsModel.path == "") ? "Home" : postsModel.path, text: $newPath, onCommit: {
                    showingNew = true
                })
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.center)
                .frame(minWidth: 100, maxWidth: 100)
                .textFieldStyle(PlainTextFieldStyle())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                SortSelectorComponent(function: postsModel.changeSortAndTime, currentSort: $postsModel.sort, currentTime: $postsModel.time)
            }
        })
        .navigationDestination(isPresented: $showingNew) {
            PostsView(postsModel: PostsModel(apiModel: apiModel, path: newPath))
        }
    }
}
