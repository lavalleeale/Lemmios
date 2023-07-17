import LemmyApi
import SwiftUI

struct ResolveView<T: ResolveResponse>: View {
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel 
    @StateObject var resolveModel: ResolveModel<T>
    @State var showingConfirm = false
    var body: some View {
        Group {
            ProgressView()
        }
        .navigationTitle("Loading")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: resolveModel.value) { newValue in
            if let newValue = newValue {
                switch newValue {
                case let postResponse as LemmyApi.PostResolveResponse:
                    navModel.path.removeLast()
                    navModel.path.append(PostModel(post: postResponse.post))
                default:
                    navModel.path.removeLast()
                }
            }
        }
        .alert("Login", isPresented: $showingConfirm) {
            Button("Cancel", role: .cancel) { navModel.path.removeLast() }
            Button("Log in") { apiModel.getAuth() }
        }
        .onChange(of: apiModel.selectedAccount) { newValue in
            if newValue != nil {
                resolveModel.resolve(apiModel: apiModel)
            }
        }
        .onAppear {
            if apiModel.selectedAccount == nil {
                showingConfirm = true
            } else {
                resolveModel.resolve(apiModel: apiModel)
            }
        }
    }
}
