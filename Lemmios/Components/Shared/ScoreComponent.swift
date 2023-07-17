import SwiftUI

struct ScoreComponent<T: VotableModel>: View {
    @ObservedObject var votableModel: T
    @EnvironmentObject var apiModel: ApiModel
    @AppStorage("compact") var compact = false
    var preview = false

    var body: some View {
        HStack(spacing: compact && preview ? 0 : 3) {
            Image(systemName: "arrow.up")
                .scaleEffect(compact && preview ? 0.5 : 0.8)
            Text(formatNum(num: votableModel.score))
                .font(compact && preview ? .caption: nil)
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
