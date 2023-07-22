import SwiftUI
import AlertToast

struct DefaultStartComponent: View {
    @State private var showingCustom = false
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var searchedModel = SearchedModel(query: "", searchType: .Communities)
    @Binding var selection: DefaultStart

    let desciption: String
    let options: [DefaultStart]
    let customDescription: String

    var body: some View {
        SettingViewComponent(selection: $selection, desciption: desciption, options: options)
            .popupNavigationView(isPresented: $showingCustom) {
                CommunitySelectorComponent(placeholder: customDescription) { text in
                    if text != "" {
                        self.selection = .Community(name: text)
                    }
                    showingCustom = false
                }
                .ignoresSafeArea(.keyboard)
            }
            .onChange(of: selection.rawValue) { [selection] newValue in
                if newValue == "c/" {
                    self.showingCustom = true
                    UserDefaults.standard.set(selection.rawValue, forKey: "defaultStart")
                }
            }
            .toast(isPresenting: $searchedModel.rateLimited) {
                AlertToast(displayMode: .banner(.pop), type: .error(.red), title: "Search rate limit reached")
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
