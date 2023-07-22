import SwiftUI

struct CommunitySelectorComponent: View {
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)

    @State var text = ""
    let placeholder: String
    let callback: (String) -> Void

    var body: some View {
        ColoredListComponent {
            Group {
                TextField(placeholder, text: $text) {
                    callback(text)
                }
                if let communities = searchedModel.communities?.filter({ $0.community.name.lowercased().contains(text.lowercased()) }).prefix(5), communities.count != 0 {
                    CommmunityListComponent(communities: communities) { community in
                        callback("\(community.community.name)@\(community.community.actor_id.host()!)")
                    }
                }
            }
            .onChange(of: text) { newValue in
                self.searchedModel.reset(removeResults: false)
                if newValue != "" {
                    self.searchedModel.query = newValue
                    self.searchedModel.fetchCommunties(apiModel: apiModel, reset: true)
                }
            }
            .onAppear {
                text = ""
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle("Select Community")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    callback("")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    callback(text)
                }
            }
        }
    }
}
