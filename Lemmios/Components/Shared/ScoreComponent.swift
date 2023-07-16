import SwiftUI

struct ScoreComponent<T: VotableModel>: View {
    @ObservedObject var votableModel: T
    @EnvironmentObject var apiModel: ApiModel

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "arrow.up")
                .scaleEffect(0.5)
            Text(formatNum(num: votableModel.score))
                .font(.caption)
        }
        .accessibility(addTraits: .isButton)
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
            votableModel.vote(direction: true, apiModel: apiModel)
        }
        .foregroundColor(votableModel.likes == 1 ? .orange : votableModel.likes == -1 ? .purple : .gray)
    }
}
