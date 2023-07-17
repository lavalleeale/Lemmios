import LemmyApi
import SwiftUI
import AlertToast

struct SearchView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @StateObject var searchModel = SearchModel()
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @State var query = ""
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel

    var body: some View {
        let typing = query != ""
        VStack {
            ColoredListComponent {
                Section {
                    ForEach(SearchedModel.SearchType.allCases, id: \.self) { type in
                        NavigationLink(value: SearchedModel(query: query, searchType: type)) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("\(type.rawValue) with \"\(query)\"")
                            }
                        }
                    }
                }
                if let communities = searchedModel.communities?.filter({ $0.community.name.contains(query.lowercased()) }).prefix(10), communities.count != 0 {
                    Section {
                        CommmunityListComponent(communities: communities)
                    }
                }
            }
            .onChange(of: query) { newValue in
                self.searchedModel.reset(removeResults: false)
                if newValue != "" {
                    self.searchedModel.query = newValue
                    self.searchedModel.fetchCommunties(apiModel: apiModel, reset: true)
                }
            }
            .toast(isPresenting: $searchedModel.rateLimited) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Search rate limit reached")
            }
            .frame(maxHeight: typing ? .infinity : 0)
            .clipped()
            ColoredListComponent {
                if searchModel.communities.count == 0 {
                    HStack {
                        Text("Loading Rising...")
                        Spacer()
                        ProgressView()
                    }
                }
                CommmunityListComponent(communities: searchModel.communities, rising: true)
            }
            .frame(maxHeight: typing ? 0 : .infinity)
            .clipped()
        }
        .background(selectedTheme.backgroundColor)
        .navigationBarTitle("Search", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Search", text: $query) {
                    if query != "" {
                        navModel.path.append(SearchedModel(query: query, searchType: .Posts))
                    }
                }
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.center)
                .frame(maxWidth: UIScreen.main.bounds.width / 1.5, minHeight: 30)
                .background(RoundedRectangle(cornerRadius: 10.0).fill(.secondary.opacity(0.5)))
            }
        }
        .onAppear {
            searchModel.sort = .Top
            searchModel.fetchCommunties(apiModel: apiModel)
        }
        .animation(.linear, value: typing)
    }
}

struct CommmunityListComponent<T: RandomAccessCollection<LemmyApi.ApiCommunity>>: View {
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    let communities: T
    var rising = false

    var callback: ((LemmyApi.ApiCommunity) -> Void)?

    var body: some View {
        ForEach(communities) { community in
            HStack {
                if rising {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                    Spacer()
                    ShowFromComponent(item: community.community, show: true)
                } else {
                    ShowFromComponent(item: community.community, show: true)
                    Spacer()
                    Text("\(community.counts.subscribers) Subscribers")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let callback = callback {
                    callback(community)
                } else {
                    let communityHost = community.community.actor_id.host()!
                    navModel.path.append(PostsModel(
                        path: community.community.local ? community.community.name : "\(community.community.name)@\(communityHost)"))
                }
            }
            .buttonStyle(.plain)
        }
    }
}
