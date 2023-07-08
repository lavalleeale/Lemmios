import SwiftUI

struct NSFWBadgeComponent: View {
    var body: some View {
        Text("NSFW")
            .foregroundStyle(.white)
            .padding(.all, 3)
            .background(
                Rectangle().fill(.red).clipShape(.capsule)
            )
    }
}
