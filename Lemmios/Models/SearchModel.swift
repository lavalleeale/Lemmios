import Foundation
import Combine

class SearchModel: ObservableObject {
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var communities = [LemmyHttp.ApiCommunity]()
    @Published var sort = LemmyHttp.Sort.Active
    @Published var time = LemmyHttp.TopTime.All
    @Published var pageStatus = CommentsPageStatus.ready
    
    func fetchCommunties(apiModel: ApiModel) {
        guard case .ready = pageStatus else {
            return
        }
        pageStatus = .loading
        apiModel.lemmyHttp!.getCommunities(page: 1, sort: sort, time: time, limit: 5) { communities, error in
            if error == nil {
                self.communities.append(contentsOf: communities!.communities)
                self.pageStatus = .done
            } else {
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
}
