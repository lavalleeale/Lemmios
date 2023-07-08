import SwiftUI

struct ImportSubsView: View {
    @EnvironmentObject var navModel: NavModel
    let requestedSubs: [String]
    var body: some View {
        List(requestedSubs, id: \.self) { requestedSub in
            NavigationLink(requestedSub, value: SearchedModel(query: requestedSub, searchType: .Communities))
        }
    }
}
