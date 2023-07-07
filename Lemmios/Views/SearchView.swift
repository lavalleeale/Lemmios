import SwiftUI

struct SearchView: View {
    @ObservedObject var searchModel: SearchModel
    @State var query = ""
    @State var typing = false
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel

    var body: some View {
        VStack {
            List(SearchedModel.SearchType.allCases, id: \.self) { type in
                NavigationLink(value: SearchedModel(query: query, searchType: type)) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("\(type.rawValue) with \"\(query)\"")
                    }
                }
            }
            .frame(maxHeight: typing ? .infinity : 0)
            .clipped()
            List(searchModel.communities) { community in
                let communityHost = community.community.actor_id.host()!
                let apiHost = URL(string: apiModel.url)!.host()!
                NavigationLink(value: PostsModel(
                    path: apiHost == communityHost ? community.community.name : "\(community.community.name)@\(communityHost)")
                ) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                        Spacer()
                        ShowFromComponent(item: community.community)
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxHeight: typing ? 0 : .infinity)
            .clipped()
        }
        .navigationBarTitle("Search", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Search", text: $query) {
                    navModel.path.append(SearchedModel(query: query, searchType: .Posts))
                }
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.center)
                .frame(minWidth: 100, maxWidth: 100)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: query) { newValue in
                    withAnimation {
                        typing = newValue != ""
                    }
                }
            }
        }
        .onAppear {
            searchModel.sort = .Hot
            searchModel.fetchCommunties(apiModel: apiModel)
        }
    }
}
