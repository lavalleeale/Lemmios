import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStart") var defaultStart = DefaultStart.Subscribed
    @AppStorage("defaultPostSort") var defaultPostSort = LemmyHttp.Sort.Active
    @AppStorage("defaultCommentSort") var defaultCommentSort = LemmyHttp.Sort.Hot
    @AppStorage("defaultPostSortTime") var defaultPostSortTime = LemmyHttp.TopTime.All
    @State var showingChangeInstance = false
    @EnvironmentObject var apiModel: ApiModel

    init() {
        if let data = UserDefaults.standard.data(forKey: "settings"), let decoded = try? JSONDecoder().decode(OldSettings.self, from: data) {
            self.defaultStart = decoded.defaultStart
            self.defaultPostSort = decoded.defaultPostSort
            self.defaultCommentSort = decoded.defaultCommentSort
            self.defaultPostSortTime = decoded.defaultPostSortTime
            UserDefaults.standard.removeObject(forKey: "settings")
            return
        }
    }

    var body: some View {
        List {
            Section("Posts") {
                SettingViewSuboption(selection: $defaultPostSort, suboption: $defaultPostSortTime, desciption: "Default Sort", options: LemmyHttp.Sort.allCases)
            }
            Section("Comments") {
                SettingView(selection: $defaultCommentSort, desciption: "Default Sort", options: LemmyHttp.Sort.allCases.filter { $0.comments })
            }
            Section("Other") {
                SettingViewCustom(selection: $defaultStart, desciption: "Default Community", options: DefaultStart.allCases, base: "c/", customDescription: "Community Name")
                Button("Change Instance") {
                    self.showingChangeInstance = true
                }
                .popupNavigationView(isPresented: $showingChangeInstance) {
                    ServerSelectorView() {
                        self.showingChangeInstance = false
                    }
                }
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
    }
}

enum DefaultStart: RawRepresentable, Codable, CaseIterable {
    init?(rawValue: String) {
        switch rawValue {
        case "All":
            self = .All
        case "Subscribed":
            self = .Subscribed
        case let str where str.contains("c/"):
            self = .Community(name: String(rawValue.dropFirst(2)))
        default:
            self = .All
        }
    }

    static var allCases: [DefaultStart] = [.All, .Subscribed, .Community(name: "")]

    var rawValue: String {
        switch self {
        case .All:
            return "All"
        case .Subscribed:
            return "Subscribed"
        case .Community(name: let name):
            return "c/\(name)"
        }
    }

    case All, Subscribed, Community(name: String)
}

struct OldSettings: Codable {
    let defaultStart: DefaultStart
    let defaultPostSort: LemmyHttp.Sort
    let defaultPostSortTime: LemmyHttp.TopTime
    let defaultCommentSort: LemmyHttp.Sort
}
