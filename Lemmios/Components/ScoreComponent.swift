import SwiftUI

struct ScoreComponent<T: VotableModel>: View {
    @ObservedObject var votableModel: T
    @EnvironmentObject var apiModel: ApiModel
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.up")
                .scaleEffect(0.8)
                .padding(.trailing, -5)
            Text(formatNum(num: votableModel.score))
        }
        .accessibility(addTraits: .isButton)
        .onTapGesture {
            votableModel.vote(direction: true, apiModel: apiModel)
        }
        .foregroundColor(votableModel.likes == 1 ? .orange : votableModel.likes == -1 ? .purple : .gray)
    }
}
