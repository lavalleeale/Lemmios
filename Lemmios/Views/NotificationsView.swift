import AlertToast
import SwiftUI

struct NotificationsView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @EnvironmentObject var apiModel: ApiModel
    @State var showingAddWatcher = false
    @StateObject var watchersModel = WatchersModel()
    var body: some View {
        ColoredListComponent {
            if watchersModel.deviceToken == nil {
                Button("Enable Notifications") {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            Group {
                Section {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        VStack(alignment: .leading) {
                            Text("Inbox")
                            Text("Replies, private messages")
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(apiModel.accounts) { account in
                        HStack {
                            Toggle("\(account.username)@\(account.instance)", isOn: Binding(get: { account.notificationsEnabled }, set: { newValue, _ in
                                if newValue {
                                    apiModel.enablePush(account: account)
                                } else {
                                    apiModel.disablePush(account: account)
                                }
                            }))
                        }
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "person.3.sequence")
                        VStack(alignment: .leading) {
                            Text("Community Watchers")
                            Text("Alerts for matching community posts")
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(watchersModel.watchers) { watcher in
                        Text("\(watcher.communityName)@\(watcher.instance)")
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    watchersModel.deleteWatcher(watcher: watcher)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    Button {
                        showingAddWatcher = true
                    } label: {
                        Label("Add Watcher", systemImage: "plus")
                    }
                }
            }.disabled(watchersModel.deviceToken == nil)
        }
        .sheet(isPresented: $showingAddWatcher, content: {
            if #available(iOS 16.4, *) {
                AddWatcherComponent(watchersModel: watchersModel)
                    .presentationBackground(selectedTheme.secondaryColor)
            } else {
                AddWatcherComponent(watchersModel: watchersModel)
            }
        })
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toast(isPresenting: Binding(get: {watchersModel.error != nil}, set: {_ in watchersModel.error = nil})) {
            AlertToast(displayMode: .banner(.pop), type: .error(.red), title: watchersModel.error ?? "Error")
        }
        .toast(isPresenting: $watchersModel.created) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: "Created")
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationsView()
                .environmentObject(ApiModel())
        }
    }
}
