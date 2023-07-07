import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    var body: some View {
        List {
            Section("Posts") {
                SettingViewSuboption(selection: $settingsModel.defaultPostSort, suboption: $settingsModel.defaultPostSortTime, desciption: "Default Sort", options: LemmyHttp.Sort.allCases)
            }
            Section("Comments") {
                SettingView(selection: $settingsModel.defaultCommentSort, desciption: "Default Sort", options: LemmyHttp.Sort.allCases.filter { $0.comments })
            }
            Section("Other") {
                SettingViewCustom(selection: $settingsModel.defaultStart, desciption: "Default Community", options: SettingsModel.DefaultStart.allCases, base: "c/", customDescription: "Community Name")
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

struct SettingViewCustom<T>: View where T: RawRepresentable, T.RawValue == String {
    @State private var showingCustom = false
    @Binding var selection: T

    let desciption: String
    let options: [T]
    let base: String
    let customDescription: String

    var body: some View {
        SettingView(selection: $selection, desciption: desciption, options: options)
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

struct SettingViewSuboption<T>: View where T: Equatable, T: HasCustom, T: RawRepresentable, T.RawValue == String {
    @State private var showingOptions = false
    @State private var showingSuboption = false
    @Binding var selection: T
    @Binding var suboption: T.T
    let desciption: String
    let options: [T]

    var body: some View {
        SettingView(selection: $selection, desciption: desciption, options: options)
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

struct SettingView<T>: View where T: RawRepresentable, T.RawValue == String {
    @State private var showingOptions = false
    @Binding var selection: T
    let desciption: String
    let options: [T]

    var body: some View {
        Button {
            showingOptions = true
        } label: {
            HStack {
                Text(desciption)
                Spacer()
                Text(selection.rawValue)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .confirmationDialog("\(desciption)...", isPresented: $showingOptions, titleVisibility: .visible) {
            ForEach(options, id: \.rawValue) { option in
                Button(option.rawValue) {
                    selection = option
                }
            }
        }
    }
}

protocol HasCustom {
    associatedtype T where T: RawRepresentable, T.RawValue == String
    var hasCustom: Bool { get }
    var customOptions: [T] { get }
}

extension LemmyHttp.Sort: HasCustom {
    typealias T = LemmyHttp.TopTime
    var hasCustom: Bool {
        return self.hasTime
    }

    var customOptions: [LemmyHttp.TopTime] {
        return LemmyHttp.TopTime.allCases
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsModel())
    }
}
