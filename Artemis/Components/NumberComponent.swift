import SwiftUI

struct NumberComponent: View {
    let num: Int
    var body: some View {
        Text(num < 1000 ? String(num) : String("\(round((Double(num) / 1000) * 10) / 10)K"))
    }
}
