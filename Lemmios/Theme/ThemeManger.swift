import Foundation
import SwiftUI

enum Theme: String, CaseIterable {
    case Default, Solarized, Sunset, Sepia
    
    var primaryColor: Color {
        if self == .Default, UserDefaults.standard.bool(forKey: "pureBlack")  {
            return Color("PureBlack-PrimaryColor")
        }
        return Color("\(self.rawValue)-PrimaryColor")
    }
    var secondaryColor: Color {
        if self == .Default, UserDefaults.standard.bool(forKey: "pureBlack") {
            return Color("PureBlack-SecondaryColor")
        }
        return Color("\(self.rawValue)-SecondaryColor")
    }
    var backgroundColor: Color {
        if self == .Default, UserDefaults.standard.bool(forKey: "pureBlack") {
            return Color("PureBlack-BackgroundColor")
        }
        return Color("\(self.rawValue)-BackgroundColor")
    }
    
}
