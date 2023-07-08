import SwiftUI

struct NSFWBadgeComponent: View {
    var body: some View {
        Text("NSFW")
            .padding(.all, 3)
            .background(
                Rectangle().fill(.red).clipShape(.capsule)
            )
    }
}
