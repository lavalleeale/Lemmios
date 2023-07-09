import SwiftUI
import SimpleHaptics

struct ScoreComponent<T: VotableModel>: View {
    @EnvironmentObject var haptics: SimpleHapticGenerator
    @ObservedObject var votableModel: T
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.up")
                .scaleEffect(0.8)
            Text(formatNum(num: votableModel.score))
        }
        .accessibility(addTraits: .isButton)
        .onTapGesture {
            try? haptics.fire()
            votableModel.vote(direction: true, apiModel: apiModel)
        }
        .foregroundColor(votableModel.likes == 1 ? .orange : votableModel.likes == -1 ? .purple : .gray)
    }
}
