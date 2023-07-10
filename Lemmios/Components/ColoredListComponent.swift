import SwiftUI

struct ColoredListComponent<label: View>: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    
    var customBackground: Color?
    
    @ViewBuilder var content: label
    
    var body: some View {
        List {
            content
                .listRowBackground(selectedTheme.primaryColor)
        }
        .listBackgroundModifier(backgroundColor: customBackground ?? selectedTheme.secondaryColor)
        .id(selectedTheme.rawValue)
    }
}
