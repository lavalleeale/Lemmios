import SwiftUI

struct DefaultStartComponent: View {
    @State private var showingCustom = false
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @Binding var selection: DefaultStart
    @State var custom = ""

    let desciption: String
    let options: [DefaultStart]
    let customDescription: String

    var body: some View {
        SettingViewComponent(selection: $selection, desciption: desciption, options: options)
            .popupNavigationView(isPresented: $showingCustom) {
                ColoredListComponent {
                    Group {
                        DefaultFocusView(custom: $custom, customDescription: customDescription) { custom in
                            self.selection = .Community(name: custom)
                            showingCustom = false
                        }
                        if let communities = searchedModel.communities?.filter({ $0.community.name.contains(custom.lowercased()) }).prefix(5), communities.count != 0 {
                            CommmunityListComponent(communities: communities) { community in
                                self.selection = .Community(name: "\(community.community.name)@\(community.community.actor_id.host()!)")
                                showingCustom = false
                            }
                        }
                    }
                    .onChange(of: custom) { newValue in
                        self.searchedModel.reset(removeResults: false)
                        if newValue != "" {
                            self.searchedModel.query = newValue
                            self.searchedModel.fetchCommunties(apiModel: apiModel, reset: true)
                        }
                    }
                    .onAppear {
                        custom = ""
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
            .onChange(of: selection.rawValue) { [selection] newValue in
                if newValue == "c/" {
                    self.showingCustom = true
                    UserDefaults.standard.set(selection.rawValue, forKey: "defaultStart")
                }
            }
    }
}

struct DefaultFocusView: View {
    @Binding var custom: String
    @FocusState private var isFocused: Bool
    let customDescription: String
    let onCommit: (String) -> Void
    var body: some View {
        TextField(customDescription, text: $custom, onCommit: {
            onCommit(custom)
        })
        .focused($isFocused)
        .onAppear {
            self.isFocused = true
        }
        .disableAutocorrection(true)
        .textInputAutocapitalization(.never)
    }
}
