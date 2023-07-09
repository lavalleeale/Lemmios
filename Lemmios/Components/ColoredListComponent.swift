import SwiftUI

struct ColoredListComponent<label: View>: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @ViewBuilder var content: label
    var body: some View {
        List {
            content
                .listRowBackground(selectedTheme.primaryColor)
        }
        .listBackgroundModifier(backgroundColor: selectedTheme.secondaryColor)
        .id(selectedTheme.rawValue)
    }
}
