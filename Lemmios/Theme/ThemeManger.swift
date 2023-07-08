import Foundation
import SwiftUI

enum Theme: String, CaseIterable {
    case Default, Solarized, Sepia
    
    var primaryColor: Color {
        return Color("\(self.rawValue)-PrimaryColor")
    }
    var secondaryColor: Color {
        return Color("\(self.rawValue)-SecondaryColor")
    }
    var backgroundColor: Color {
        return Color("\(self.rawValue)-BackgroundColor")
    }
    
}
