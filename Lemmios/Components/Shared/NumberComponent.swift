import SwiftUI

func formatNum(num: Int) -> String {
    num < 1000 ? String(num) : String("\(round((Double(num) / 1000) * 10) / 10)K")
}
