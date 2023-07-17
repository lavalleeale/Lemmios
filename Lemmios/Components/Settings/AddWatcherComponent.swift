import LemmyApi
import SwiftUI
import AlertToast

let placeholder = "\u{29cd}"

struct AddWatcherComponent: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @EnvironmentObject var apiModel: ApiModel
    @ObservedObject var watchersModel: WatchersModel
    @State var title = placeholder
    @State var author = placeholder
    @State var minUpvotes: Int64 = -1

    var body: some View {
        NavigationStack {
            ColoredListComponent {
                Section {
                    TextField("Community", text: $searchedModel.query)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(selectedTheme.primaryColor))
                    if let communities = searchedModel.communities?.filter({ $0.community.name.lowercased().contains(searchedModel.query.lowercased()) }).prefix(5), communities.count != 0 {
                        CommmunityListComponent(communities: communities) { community in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            self.searchedModel.query = "\(community.community.name)@\(community.community.actor_id.host()!)"
                        }
                    }
                }
                Section("Filters") {
                    Menu {
                        if title == placeholder {
                            Button {
                                title = ""
                            } label: {
                                Label("Title Contains", systemImage: "character.textbox")
                            }
                        }
                        if author == placeholder {
                            Button {
                                author = ""
                            } label: {
                                Label("Author Matches", systemImage: "person.circle")
                            }
                        }
                        if minUpvotes == -1 {
                            Button {
                                minUpvotes = 0
                            } label: {
                                Label("Minimum Upvotes", systemImage: "arrow.up")
                            }
                        }
                    } label: {
                        Label("Add Filter", systemImage: "plus")
                    }
                    if title != placeholder {
                        TextField("Title Contains", text: $title)
                    }
                    if author != placeholder {
                        TextField("Author is", text: $author)
                    }
                    if minUpvotes != -1 {
                        let formatter: NumberFormatter = {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            return formatter
                        }()
                        TextField("Target Size", value: $minUpvotes, formatter: formatter)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Create Watcher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        var split = searchedModel.query.components(separatedBy: "@")
                        if split.count == 1 {
                            searchedModel.query.append("@\(apiModel.lemmyHttp!.apiUrl.host()!)")
                            split.append(apiModel.lemmyHttp!.apiUrl.host()!)
                        }
                        watchersModel.createWatcher(
                            keywords: title == placeholder ? "" : title,
                            author: author == placeholder ? "" : author,
                            upvotes: minUpvotes,
                            community: split[0],
                            instance: split[1]
                        )
                        dismiss()
                    }
                    .disabled(searchedModel.query == "")
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .padding()
            .onReceive(
                searchedModel.$query.throttle(for: 1, scheduler: RunLoop.main, latest: true)
            ) { newValue in
                searchedModel.reset(removeResults: false)
                if newValue != "" {
                    searchedModel.fetchCommunties(apiModel: apiModel, reset: true)
                }
            }
        }
        .toast(isPresenting: $searchedModel.rateLimited) {
            AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Search rate limit reached")
        }
    }
}

struct AddWatcherComponent_Previews: PreviewProvider {
    static var previews: some View {
        Text("test")
            .sheet(isPresented: .constant(true), content: {
                if #available(iOS 16.4, *) {
                    AddWatcherComponent(watchersModel: WatchersModel())
                        .presentationBackground(Theme.Default.secondaryColor)
                } else {
                    AddWatcherComponent(watchersModel: WatchersModel())
                }
            })
            .environmentObject(ApiModel())
    }
}
