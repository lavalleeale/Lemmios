import SwiftUI

struct SettingCustomComponent<T>: View where T: RawRepresentable, T.RawValue == String {
    @State private var showingCustom = false
    @Binding var selection: T

    let desciption: String
    let options: [T]
    let base: String
    let customDescription: String

    var body: some View {
        SettingViewComponent(selection: $selection, desciption: desciption, options: options)
            .popupNavigationView(isPresented: $showingCustom) {
                DefaultFocusView(customDescription: customDescription) { custom in
                    self.selection = .init(rawValue: base + custom)!
                    showingCustom = false
                }
            }
            .onChange(of: selection.rawValue) { newValue in
                if newValue == base {
                    self.showingCustom = true
                }
            }
    }
}
