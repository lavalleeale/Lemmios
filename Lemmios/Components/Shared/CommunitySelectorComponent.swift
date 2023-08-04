import SwiftUI

struct CommunitySelectorComponent: View {
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)

    @State var text = ""
    let placeholder: String
    let callback: (String, Int?) -> Void
    let allowName: Bool
    
    init(placeholder: String, callback: @escaping (String, Int?) -> Void) {
        self.placeholder = placeholder
        self.callback = callback
        allowName = false
    }
    
    init(placeholder: String, callback: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.callback = {str, int in callback(str)}
        allowName = true
    }

    var body: some View {
        ColoredListComponent {
            Group {
                TextField(placeholder, text: $text) {
                    if allowName {
                        callback(text, nil)
                    }
                }
                if let communities = searchedModel.communities?.filter({ $0.community.name.lowercased().contains(text.lowercased()) }).prefix(5), communities.count != 0 {
                    CommmunityListComponent(communities: communities) { community in
                        callback("\(community.community.name)@\(community.community.actor_id.host()!)", community.id)
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
                    callback("", nil)
                }
            }
            if allowName {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        callback(text, nil)
                    }
                }
            }
        }
    }
}
