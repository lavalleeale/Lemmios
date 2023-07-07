import Combine
import Foundation

class SettingsModel: ObservableObject {
    @Published var defaultStart: DefaultStart!
    @Published var defaultPostSort: LemmyHttp.Sort!
    @Published var defaultCommentSort: LemmyHttp.Sort!
    @Published var defaultPostSortTime: LemmyHttp.TopTime!
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()
    private var savedSettings: SavedSettings
    private var cancellable: Set<AnyCancellable> = Set()
    
    init() {
        guard let data = UserDefaults.standard.data(forKey: "settings"), let decoded = try? decoder.decode(SavedSettings.self, from: data) else {
            self.savedSettings = SavedSettings()
            restoreSelf(savedSettings: SavedSettings())
            registerChangeHandlers()
            return
        }
        self.savedSettings = decoded
        restoreSelf(savedSettings: decoded)
        registerChangeHandlers()
    }
    
    private func registerChangeHandlers() {
        $defaultStart.sink { newValue in
            if case let .Community(name: name) = newValue {
                if (name == "") {
                    return                    
                }
            }
            self.setDefaultStart(newValue: newValue!)
        }
        .store(in: &cancellable)
        $defaultPostSort.sink { newValue in
            self.setDefaultPostSort(newValue: newValue!)
        }
        .store(in: &cancellable)
        
        $defaultCommentSort.sink { newValue in
            self.setDefaultCommentSort(newValue: newValue!)
        }
        .store(in: &cancellable)
        
        $defaultPostSortTime.sink { newValue in
            self.setDefaultPostSortTime(newValue: newValue!)
        }
        .store(in: &cancellable)
    }
    
    private func restoreSelf(savedSettings: SavedSettings) {
        defaultStart = savedSettings.defaultStart
        defaultPostSort = savedSettings.defaultPostSort
        defaultCommentSort = savedSettings.defaultCommentSort
        defaultPostSortTime = savedSettings.defaultPostSortTime
    }
    
    private func saveSettings() {
        if let data = try? encoder.encode(savedSettings) {
            UserDefaults.standard.setValue(data, forKey: "settings")
        }
    }
    
    func setDefaultStart(newValue: DefaultStart) {
        savedSettings.defaultStart = newValue
        saveSettings()
    }
    
    func setDefaultPostSort(newValue: LemmyHttp.Sort) {
        savedSettings.defaultPostSort = newValue
        saveSettings()
    }
    
    func setDefaultCommentSort(newValue: LemmyHttp.Sort) {
        savedSettings.defaultCommentSort = newValue
        saveSettings()
    }
    
    func setDefaultPostSortTime(newValue: LemmyHttp.TopTime) {
        savedSettings.defaultPostSortTime = newValue
        saveSettings()
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
        
        static var allCases: [SettingsModel.DefaultStart] = [.All, .Subscribed, .Community(name: "")]
        
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
    
    struct SavedSettings: Codable {
        var defaultStart = DefaultStart.Subscribed
        var defaultPostSort = LemmyHttp.Sort.Active
        var defaultPostSortTime = LemmyHttp.TopTime.All
        var defaultCommentSort = LemmyHttp.Sort.Hot
    }
}
