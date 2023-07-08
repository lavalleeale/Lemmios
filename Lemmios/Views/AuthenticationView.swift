import AlertToast
import SwiftUI
import WebKit

struct AuthenticationView: View {
    @EnvironmentObject var apiModel: ApiModel
    @ObservedObject var authModel = AuthModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if !apiModel.serverSelected {
                ServerSelectorView()
            } else if apiModel.accounts.isEmpty {
                AuthFormComponent(authModel: authModel)
            } else {
                List(apiModel.accounts) { account in
                    Button {
                        apiModel.selectAuth(username: account.username)
                    } label: {
                        HStack {
                            Text(account.username)
                            Spacer()
                            if account.username == apiModel.selectedAccount {
                                Image(systemName: "checkmark")
                            }
                        }
                        .swipeActions {
                            Button {
                                apiModel.deleteAuth(username: account.username)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            AuthFormComponent(authModel: authModel)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
}

enum AuthType: String, CaseIterable, Identifiable {
    case Login, Signup

    var id: Self { self }
}
