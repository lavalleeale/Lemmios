import AlertToast
import SwiftUI

struct ApolloImportView: View {
    @ObservedObject var apolloImportModel = ApolloImportModel()
    @EnvironmentObject var navModel: NavModel
    @State private var importing = false
    @State var showingError = false

    var body: some View {
        Button("Import From Apollo") {
            importing = true
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let file):
                if let users = apolloImportModel.read(from: file) {
                    navModel.path.append(ApolloImportDestination.Main(users: users))
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .toast(isPresenting: $showingError) {
            AlertToast(displayMode: .hud, type: .error(.red), title: "Wrong file picked")
        }
        .navigationDestination(for: ApolloImportDestination.self) { value in
            switch value {
            case .Import(let subs):
                ImportSubsView(requestedSubs: subs)
            case .Main(let users):
                ColoredListComponent {
                    ForEach(users.sorted { $0.key > $1.key }, id: \.key) { key, value in
                        NavigationLink(key, value: ApolloImportDestination.Import(subs: value.subscribed_subreddits))
                    }
                }
            }
        }
    }
}

enum ApolloImportDestination: Hashable {
    case Import(subs: [String]), Main(users: [String: ApolloUserData])
}
