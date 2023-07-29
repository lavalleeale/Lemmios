import LemmyApi
import SwiftUI

struct ResolveView<T: Codable>: View where T: Equatable {
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel 
    @StateObject var resolveModel: ResolveModel<T>
    @State var showingConfirm = false
    var body: some View {
        ColoredListComponent {
            if let error = resolveModel.error {
                Text("Lemmy Error, please refresh")
            } else {
                ProgressView()
            }
        }
        .refreshable {
            if resolveModel.thing.host() != apiModel.lemmyHttp?.apiUrl.host(), apiModel.selectedAccount == nil {
                showingConfirm = true
            } else {
                resolveModel.resolve(apiModel: apiModel)
            }
        }
        .navigationTitle("Loading")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: resolveModel.value) { newValue in
            if let newValue = newValue {
                switch newValue {
                case let postResponse as LemmyApi.PostView:
                    navModel.path.removeLast()
                    navModel.path.append(PostModel(post: postResponse.post))
                case let postResponse as LemmyApi.CommentView:
                    navModel.path.removeLast()
                    navModel.path.append(PostModel(post: postResponse.post, comment: postResponse.comment))
                default:
                    navModel.path.removeLast()
                }
            }
        }
        .alert("Login", isPresented: $showingConfirm) {
            Button("Cancel", role: .cancel) { navModel.path.removeLast() }
            Button("Log in") { apiModel.getAuth() }
        } message: {
            Text("Lemmy requires authentication for resolving data from remote instances")
        }
        .onChange(of: apiModel.selectedAccount) { newValue in
            if newValue != nil {
                resolveModel.resolve(apiModel: apiModel)
            }
        }
        .onAppear {
            if resolveModel.thing.host() != apiModel.lemmyHttp?.apiUrl.host(), apiModel.selectedAccount == nil {
                showingConfirm = true
            } else {
                resolveModel.resolve(apiModel: apiModel)
            }
        }
    }
}
