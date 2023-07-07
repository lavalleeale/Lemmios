import SimpleHaptics
import SwiftUI

struct ArrowsComponent<T: VotableModel>: View {
    @ObservedObject var votableModel: T
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        Image(systemName: "arrow.up")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(votableModel.likes == 1 ? .white : .secondary)
            .padding(.all, 10)
            .background(votableModel.likes == 1 ? .orange : .clear)
            .cornerRadius(5)
            .highPriorityGesture(TapGesture().onEnded {
                try? haptics.fire()
                votableModel.vote(direction: true, apiModel: apiModel)
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
                votableModel.vote(direction: false, apiModel: apiModel)
            })
    }
}
