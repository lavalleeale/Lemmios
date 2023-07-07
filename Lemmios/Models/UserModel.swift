import Foundation
import Combine

class UserModel: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var pageStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var sort = LemmyHttp.Sort.Active
    @Published var time = LemmyHttp.TopTime.All
    @Published var userData: LemmyHttp.PersonView?
    
    @Published var name: String
    
    private var cancellable: Set<AnyCancellable> = Set()
    
    init(user: LemmyHttp.ApiUserData) {
        self.name = "\(user.name)@\(user.actor_id.host()!)"
    }
    
    
    init(path: String) {
        self.name = path
    }
    
    func fetchData(apiModel: ApiModel) {
        let apiHost = URL(string: apiModel.url)!.host()!
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp!.getUser(name: self.name, page: page, sort: sort, time: time) { user, error in
            if error == nil {
                self.userData = user
            } else {
                print(error)
                self.pageStatus = .failed
            }
        }.store(in: &cancellable)
    }
}
