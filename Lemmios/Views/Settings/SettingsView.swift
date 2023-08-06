import AlertToast
import Combine
import LemmyApi
import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStart") var defaultStart = DefaultStart.All
    @AppStorage("defaultPostSort") var defaultPostSort = LemmyApi.Sort.Active
    @AppStorage("defaultCommentSort") var defaultCommentSort = LemmyApi.Sort.Hot
    @AppStorage("defaultPostSortTime") var defaultPostSortTime = LemmyApi.TopTime.All
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("colorScheme") var colorScheme = ColorScheme.System
    @AppStorage("pureBlack") var pureBlack = false
    @AppStorage("blurNSFW") var blurNsfw = true
    @AppStorage("fontSize") var fontSize: Double = -1
    @AppStorage("systemFont") var systemFont = true
    @AppStorage("commentImages") var commentImages = true
    @AppStorage("compact") var compactPosts = false
    @AppStorage("showInstances") var showInstances = true
    @AppStorage("hideRead") var hideRead = false
    @AppStorage("enableRead") var enableRead = true
    @AppStorage("readOnScroll") var readOnScroll = false
    @AppStorage("totalScore") var totalScore = true
    @AppStorage("swipeDistance") var swipeDistance = SwipeDistance.Normal
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var showingDelete = false
    @State var deletePassword = ""
    @StateObject var settingsModel = SettingsModel()
    @Environment(\.dynamicTypeSize) var size: DynamicTypeSize

    var body: some View {
        ColoredListComponent {
            Section("General") {
                NavigationLink("Open Lemmy Links in Lemmios", value: SettingsNav.OpenInLemmios)
                Toggle("Show instance names", isOn: $showInstances)
                NavigationLink("Filters", value: SettingsNav.Filters)
            }
            Section("Appearance") {
                SettingViewComponent(selection: $selectedTheme, desciption: "Theme", options: Theme.allCases)
                SettingViewComponent(selection: $colorScheme, desciption: "Color Scheme", options: ColorScheme.allCases)
                Toggle("Pure Black Dark Mode", isOn: $pureBlack)
                Toggle("Display Total Score", isOn: $totalScore)
                ZStack {
                    Slider(value: systemFont ? .constant(sizeDouble(size: size)) : $fontSize, in: 0...Double(DynamicTypeSize.allCases.filter { !$0.isAccessibilitySize }.count - 1), step: 1)
                    HStack {
                        ForEach(0...(DynamicTypeSize.allCases.filter { !$0.isAccessibilitySize }.count - 1), id: \.self) { _ in
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
                NavigationLink("Marking Read / Hiding", value: SettingsNav.Read)
                Toggle("Compact Posts", isOn: $compactPosts)
                SettingSuboptionComponent(selection: $defaultPostSort, suboption: $defaultPostSortTime, desciption: "Default Sort", options: LemmyApi.Sort.allCases)
            }
            Section("Comments") {
                SettingViewComponent(selection: $defaultCommentSort, desciption: "Default Sort", options: LemmyApi.Sort.allCases.filter { $0.comments })
                Toggle("Show Images in Comments", isOn: $commentImages)
            }
            Section("Other") {
                NavigationLink("Notifications", value: SettingsNav.Notifications)
                NavigationLink("App Icon", value: SettingsNav.AppIcon)
                SettingViewComponent(selection: $swipeDistance, desciption: "Long Swipe Trigger Point", options: SwipeDistance.allCases)
                if apiModel.nsfw {
                    Toggle("Blur NSFW", isOn: $blurNsfw)                    
                }
                DefaultStartComponent(selection: $defaultStart, desciption: "Default Community", options: DefaultStart.allCases, customDescription: "Community Name")
                NavigationLink("Change Instance", value: SettingsNav.ServerSelector)
                if apiModel.selectedAccount != nil {
                    Button("Delete Account") {
                        showingDelete = true
                    }
                }
            }
            NavigationLink("About", value: SettingsNav.About)
            ApolloImportView()
        }
        .alert("Delete Account", isPresented: $showingDelete) {
            SecureField("Password", text: $deletePassword)
            Button("Delete", role: .destructive) {
                settingsModel.deleteAccount(password: deletePassword, apiModel: apiModel)
            }
            Button("Cancle", role: .cancel) {}
        }
        .toast(isPresenting: Binding(get: { settingsModel.deleteResponse != nil }, set: { _ in
            settingsModel.deleteResponse = nil
            settingsModel.deleteError = nil
        })) {
            AlertToast(displayMode: .banner(.pop), type: settingsModel.deleteResponse == true ? .complete(.green) : .error(.red), title: settingsModel.deleteResponse == true ? "Account deleted" : settingsModel.deleteError ?? "Unkown error deleting account")
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
            case .ServerSelector:
                ServerSelectorView {
                    navModel.clear()
                }
            case .Notifications:
                NotificationsView()
            case .Read:
                ColoredListComponent {
                    Toggle("Disable Marking Posts Read", isOn: Binding(get: { !enableRead }, set: { enableRead = !$0 }))
                    if enableRead {
                        Toggle("Auto Hide Read Posts", isOn: $hideRead)
                        Toggle("Mark Read On Scroll", isOn: $readOnScroll)
                    }
                    Button("Clear Read") {
                        DBModel.instance.clear()
                    }
                }
            case .OpenInLemmios:
                OpenInLemmiosView()
            case .Filters:
                FiltersView()
            case .Reminders:
                RemindersView()
            case .AppIcon:
                IconsView()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum SettingsNav: String, Hashable {
    case About, ServerSelector, Read, Notifications, OpenInLemmios, Filters, Reminders, AppIcon
}

protocol HasCustom {
    associatedtype T where T: RawRepresentable, T.RawValue == String
    var hasCustom: Bool { get }
    var customOptions: [T] { get }
}

extension LemmyApi.Sort: HasCustom {
    typealias T = LemmyApi.TopTime
    var hasCustom: Bool {
        return self.hasTime
    }

    var customOptions: [LemmyApi.TopTime] {
        return LemmyApi.TopTime.allCases
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

enum SwipeDistance: String, CaseIterable {
    case Earlier, Normal, Later
    var distance: Double {
        switch self {
        case .Earlier:
            return 125
        case .Normal:
            return 175
        case .Later:
            return 250
        }
    }
}

func sizeDouble(size: DynamicTypeSize) -> Double {
    Double(DynamicTypeSize.allCases.firstIndex(of: size)!)
}
