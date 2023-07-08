import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStart") var defaultStart = DefaultStart.Subscribed
    @AppStorage("defaultPostSort") var defaultPostSort = LemmyHttp.Sort.Active
    @AppStorage("defaultCommentSort") var defaultCommentSort = LemmyHttp.Sort.Hot
    @AppStorage("defaultPostSortTime") var defaultPostSortTime = LemmyHttp.TopTime.All
    @AppStorage("shouldCompressPostOnSwipe") var shouldCompressPostOnSwipe = false
    @State var showingChangeInstance = false
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            Section("Posts") {
                SettingSuboptionComponent(selection: $defaultPostSort, suboption: $defaultPostSortTime, desciption: "Default Sort", options: LemmyHttp.Sort.allCases)
            }
            Section("Comments") {
                SettingViewComponent(selection: $defaultCommentSort, desciption: "Default Sort", options: LemmyHttp.Sort.allCases.filter { $0.comments })
            }
            Section("Other") {
                SettingCustomComponent(selection: $defaultStart, desciption: "Default Community", options: DefaultStart.allCases, base: "c/", customDescription: "Community Name")
                Toggle("Dynamic text size on swipe", isOn: $shouldCompressPostOnSwipe)
                Button("Change Instance") {
                    self.showingChangeInstance = true
                }
                .popupNavigationView(isPresented: $showingChangeInstance) {
                    ServerSelectorView {
                        self.showingChangeInstance = false
                    }
                }
            }
            NavigationLink("About", value: SettingsNav.About)
            ApolloImportView()
        }
        .navigationDestination(for: SettingsNav.self) { location in
            switch location {
            case .About:
                AboutView()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum SettingsNav: String, Hashable {
    case About
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
