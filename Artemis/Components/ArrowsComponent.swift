import SwiftUI
import SimpleHaptics

struct ArrowsComponent<T: VotableModel>: View {
    @ObservedObject var votableModel: T
    @EnvironmentObject var haptics: SimpleHapticGenerator

    var body: some View {
        HStack {
            Image(systemName: "arrow.up")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(votableModel.likes == 1 ? .white : .secondary)
                .padding(.all, 10)
                .background(votableModel.likes == 1 ? .orange : .clear)
                .cornerRadius(5)
                .highPriorityGesture(TapGesture().onEnded {
                    try? haptics.fire()
                    votableModel.vote(direction: true)
                })
            Image(systemName: "arrow.down")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(votableModel.likes == -1 ? .white : .secondary)
                .padding(.all, 10)
                .background(votableModel.likes == -1 ? .purple : .clear)
                .cornerRadius(5)
                .highPriorityGesture(TapGesture().onEnded {
                    try? haptics.fire()
                    votableModel.vote(direction: false)
                })
        }
    }
}
