import SwiftUI

struct ScoreComponent<T: VotableModel>: View {
    @ObservedObject var votableModel: T
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.up")
                .scaleEffect(0.8)
                .padding(.trailing, -5)
            NumberComponent(num: votableModel.score)
        }
        .accessibility(addTraits: .isButton)
        .onTapGesture {
            votableModel.vote(direction: true)
        }
        .foregroundColor(votableModel.likes == 1 ? .orange : votableModel.likes == -1 ? .purple : .gray)
    }
}
