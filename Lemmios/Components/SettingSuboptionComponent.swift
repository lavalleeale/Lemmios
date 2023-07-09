import SwiftUI

struct SettingSuboptionComponent<T>: View where T: Equatable, T: HasCustom, T: RawRepresentable, T.RawValue == String {
    @State private var showingOptions = false
    @State private var showingSuboption = false
    @Binding var selection: T
    @Binding var suboption: T.T
    let desciption: String
    let options: [T]

    var body: some View {
        SettingViewComponent(selection: $selection, desciption: desciption, options: options)
            .confirmationDialog("", isPresented: $showingSuboption, titleVisibility: .hidden) {
                ForEach(selection.customOptions, id: \.rawValue) { option in
                    HStack {
                        Button(option.rawValue) {
                                suboption = option
                        }
                    }
                }
            }
            .onChange(of: selection) { _ in
                if selection.hasCustom {
                    showingSuboption = true
                }
            }
    }
}

struct DefaultFocusView: View {
    @State private var custom = ""
    @FocusState private var isFocused: Bool
    let customDescription: String
    let onCommit: (String) -> Void
    var body: some View {
        Form {
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
}
