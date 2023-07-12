import Combine
import Foundation
import OSLog

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
    @Published var userData: LemmyHttp.ApiUser?
    @Published var comments = [LemmyHttp.ApiComment]()
    @Published var posts = [LemmyHttp.ApiPost]()
    
    @Published var saved = [any WithCounts]()
    @Published var savedPageStatus = PostsPageStatus.ready(nextPage: 1)
    
    @Published var name: String
    @Published var blocked = false
    
    private var userId: Int?
    
    private var cancellable: Set<AnyCancellable> = Set()
    
    init(user: LemmyHttp.ApiUserData) {
        self.name = "\(user.name)"
        if !user.local {
            name.append("@\(user.actor_id.host()!)")
        }
        self.userId = user.id
    }
    
    init(path: String) {
        self.name = path
    }
    
    func reset() {
        pageStatus = .ready(nextPage: 1)
        comments = .init()
        posts = .init()
        saved = .init()
        cancellable.removeAll()
        savedPageStatus = .ready(nextPage: 1)
    }
    
    func fetchData(apiModel: ApiModel, saved: Bool = false) {
        guard case let .ready(page) = saved ? savedPageStatus : pageStatus else {
            return
        }
        if saved {
            savedPageStatus = .loading(page: page)
        } else {
            pageStatus = .loading(page: page)
        }
        apiModel.lemmyHttp?.getUser(name: name, page: page, sort: sort, time: time, saved: saved) { user, error in
            DispatchQueue.main.async {
                if let user = user {
                    self.userData = user.person_view
                    if saved {
                        if user.comments!.isEmpty && user.posts!.isEmpty {
                            self.savedPageStatus = .done
                        } else {
                            self.saved.append(contentsOf: user.comments!)
                            self.saved.append(contentsOf: user.posts!)
                            self.savedPageStatus = .ready(nextPage: page + 1)
                        }
                    } else {
                        if user.comments!.isEmpty && user.posts!.isEmpty {
                            self.pageStatus = .done
                        } else {
                            self.comments.append(contentsOf: user.comments!)
                            self.posts.append(contentsOf: user.posts!)
                            self.pageStatus = .ready(nextPage: page + 1)
                        }
                    }
                } else {
                    os_log("\(error)")
                    self.pageStatus = .failed
                }
            }
        }.store(in: &cancellable)
    }
    
    func message(content: String, apiModel: ApiModel) {
        if let userId = userId {
            apiModel.lemmyHttp?.sendMessage(to: userId, content: content) { _, _ in }.store(in: &cancellable)
        }
    }
    
    func block(apiModel: ApiModel, block: Bool) {
        if let id = userId {
            apiModel.lemmyHttp?.blockUser(id: id, block: block) { userView, _ in
                if let userView = userView {
                    DispatchQueue.main.async {
                        self.userData = userView.person_view
                        self.blocked.toggle()
                    }
                }
            }.store(in: &cancellable)
        }
    }
}
