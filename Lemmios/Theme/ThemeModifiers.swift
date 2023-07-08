import SwiftUI

struct ListBackgroundColorModifier: ViewModifier {
    let backgroundColor: Color
    init(backgroundColor: Color) {
        self.backgroundColor = backgroundColor
        UITableView.appearance().backgroundColor = UIColor(backgroundColor)
    }

    func body(content: Content) -> some View {
        content
    }
}

extension List {
    func listBackgroundModifier(backgroundColor: Color) -> some View {
        self
            .background(backgroundColor)
            .scrollContentBackground(.hidden)
    }
}

struct NavigationBarCustomModifier: ViewModifier {
    init(backgroundColor: UIColor, tintColor: UIColor? = nil, hideseperator: Bool = false) {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithDefaultBackground()
        coloredAppearance.backgroundColor = backgroundColor
        if hideseperator {
            UINavigationBar.appearance().tintColor = .clear
        }
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        if let tintColor = tintColor {
            UINavigationBar.appearance().tintColor = tintColor
        }
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func navigationBarModifier(backgroundColor: UIColor, tintColor: UIColor? = nil, hideseperator: Bool = false) -> some View {
        self.modifier(NavigationBarCustomModifier(backgroundColor: backgroundColor, tintColor: tintColor, hideseperator: hideseperator))
    }
}
