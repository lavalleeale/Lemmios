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

struct NavigationBarCustomModifier: ViewModifier {
    init(theme: Theme) {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithDefaultBackground()
        coloredAppearance.backgroundColor = UIColor(theme.backgroundColor)
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func navigationBarModifier(theme: Theme) -> some View {
        self.modifier(NavigationBarCustomModifier(theme: theme))
    }
    
    func listBackgroundModifier(backgroundColor: Color) -> some View {
        self
            .background(backgroundColor)
            .scrollContentBackground(.hidden)
    }
}
