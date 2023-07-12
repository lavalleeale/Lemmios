import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStart") var defaultStart = DefaultStart.Subscribed
    @AppStorage("defaultPostSort") var defaultPostSort = LemmyHttp.Sort.Active
    @AppStorage("defaultCommentSort") var defaultCommentSort = LemmyHttp.Sort.Hot
    @AppStorage("defaultPostSortTime") var defaultPostSortTime = LemmyHttp.TopTime.All
    @AppStorage("shouldCompressPostOnSwipe") var shouldCompressPostOnSwipe = false
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("colorScheme") var colorScheme = ColorScheme.System
    @AppStorage("pureBlack") var pureBlack = false
    @AppStorage("blurNSFW") var blurNsfw = true
    @AppStorage("fontSize") var fontSize: Double = -1
    @AppStorage("systemFont") var systemFont = true
    @AppStorage("commentImages") var commentImages = true
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @Environment(\.dynamicTypeSize) var size: DynamicTypeSize

    var body: some View {
        ColoredListComponent {
            Section("Appearance") {
                SettingViewComponent(selection: $selectedTheme, desciption: "Theme", options: Theme.allCases)
                SettingViewComponent(selection: $colorScheme, desciption: "Color Scheme", options: ColorScheme.allCases)
                Toggle("Pure Black Dark Mode", isOn: $pureBlack)
                ZStack {
                    Slider(value: systemFont ? .constant(sizeDouble(size: size)) : $fontSize, in: 0...Double(DynamicTypeSize.allCases.filter {!$0.isAccessibilitySize}.count - 1), step: 1)
                    HStack {
                        ForEach(0...(DynamicTypeSize.allCases.filter {!$0.isAccessibilitySize}.count - 1), id: \.self) { _ in
                            Divider()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, -9)
                }
                .disabled(systemFont)
                Toggle("Use System Font Size", isOn: $systemFont)
            }
            Section("Posts") {
                SettingSuboptionComponent(selection: $defaultPostSort, suboption: $defaultPostSortTime, desciption: "Default Sort", options: LemmyHttp.Sort.allCases)
            }
            Section("Comments") {
                SettingViewComponent(selection: $defaultCommentSort, desciption: "Default Sort", options: LemmyHttp.Sort.allCases.filter { $0.comments })
                Toggle("Show Images in Comments", isOn: $commentImages)
            }
            Section("Other") {
                if apiModel.accounts.first(where: { $0.username == apiModel.selectedAccount })?.notificationsEnabled != true {
                    Button("Enable push notifications for current account") {
                        apiModel.enablePush(username: apiModel.selectedAccount)
                    }
                }
                Toggle("Blur NSFW", isOn: $blurNsfw)
                SettingCustomComponent(selection: $defaultStart, desciption: "Default Community", options: DefaultStart.allCases, base: "c/", customDescription: "Community Name")
                Toggle("Dynamic Text size On Swipe", isOn: $shouldCompressPostOnSwipe)
                NavigationLink("Change Instance") {
                    ServerSelectorView()
                }
            }
            NavigationLink("About", value: SettingsNav.About)
            ApolloImportView()
        }
        .onAppear {
            if self.fontSize == -1 {
                self.fontSize = sizeDouble(size: size)
            }
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
        case "Local":
            self = .Local
        case let str where str.contains("c/"):
            self = .Community(name: String(rawValue.dropFirst(2)))
        default:
            self = .All
        }
    }

    static var allCases: [DefaultStart] = [.All, .Subscribed, .Local, .Community(name: "")]

    var rawValue: String {
        switch self {
        case .All:
            return "All"
        case .Subscribed:
            return "Subscribed"
        case .Local:
            return "Local"
        case .Community(name: let name):
            return "c/\(name)"
        }
    }

    case All, Subscribed, Local, Community(name: String)
}

enum ColorScheme: String, CaseIterable {
    case System, Light, Dark
}

func sizeDouble(size: DynamicTypeSize) -> Double {
    Double(DynamicTypeSize.allCases.firstIndex(of: size)!)
}
