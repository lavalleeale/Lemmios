import AlertToast
import SwiftUI
import WebKit

struct AuthenticationView: View {
    @EnvironmentObject var apiModel: ApiModel
    @ObservedObject var authModel = AuthModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if apiModel.accounts.filter({ $0.instance == apiModel.lemmyHttp!.apiUrl.host() }).isEmpty {
                AuthFormComponent(authModel: authModel)
            } else {
                ColoredListComponent {
                    ForEach(apiModel.accounts) { account in
                        Button {
                            apiModel.selectAuth(account: account)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(account.username)@\(account.instance)")
                                Spacer()
                                if account == apiModel.selectedAccount {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .swipeActions {
                                Button {
                                    apiModel.deleteAuth(account: account)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            AuthFormComponent(authModel: authModel)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                })
            }
        }
    }
}

enum AuthType: String, CaseIterable, Identifiable {
    case Login, Signup

    var id: Self { self }
}
