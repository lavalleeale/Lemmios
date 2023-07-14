import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStart") var defaultStart = DefaultStart.All
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
    @AppStorage("compact") var compactPosts = false
    @AppStorage("showCommuntiies") var showCommuntiies = true
    @AppStorage("hideRead") var hideRead = false
    @AppStorage("enableRead") var enableRead = true
    @AppStorage("readOnScroll") var readOnScroll = false
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @State var showingDelete = false
    @Environment(\.dynamicTypeSize) var size: DynamicTypeSize

    var body: some View {
        ColoredListComponent {
            Section("General") {
                Toggle("Show community names", isOn: $showCommuntiies)
            }
            Section("Appearance") {
                SettingViewComponent(selection: $selectedTheme, desciption: "Theme", options: Theme.allCases)
                SettingViewComponent(selection: $colorScheme, desciption: "Color Scheme", options: ColorScheme.allCases)
                Toggle("Pure Black Dark Mode", isOn: $pureBlack)
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
                SettingSuboptionComponent(selection: $defaultPostSort, suboption: $defaultPostSortTime, desciption: "Default Sort", options: LemmyHttp.Sort.allCases)
            }
            Section("Comments") {
                SettingViewComponent(selection: $defaultCommentSort, desciption: "Default Sort", options: LemmyHttp.Sort.allCases.filter { $0.comments })
                Toggle("Show Images in Comments", isOn: $commentImages)
            }
            Section("Other") {
                if apiModel.selectedAccount?.notificationsEnabled == false {
                    Button("Enable push notifications for current account") {
                        apiModel.enablePush(account: apiModel.selectedAccount!)
                    }
                }
                Toggle("Blur NSFW", isOn: $blurNsfw)
                DefaultStartComponent(selection: $defaultStart, desciption: "Default Community", options: DefaultStart.allCases, customDescription: "Community Name")
                Toggle("Dynamic Text size On Swipe", isOn: $shouldCompressPostOnSwipe)
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
            Button("OK", role: .cancel) {}
            Link("Vist Instance", destination: URL(string: "\(apiModel.lemmyHttp!.baseUrl)/settings")!)
        } message: {
            Text("To delete your Lemmy account, you müst first visit \(apiModel.url) and sign in. Then navigate to the Profile tab. You may delete your account by pressing \"Delete Account\".")
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
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum SettingsNav: String, Hashable {
    case About, ServerSelector, Read
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
