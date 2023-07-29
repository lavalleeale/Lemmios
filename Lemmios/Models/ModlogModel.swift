import Combine
import Foundation
import LemmyApi

class ModlogModel: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: ModlogModel, rhs: ModlogModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    private var cancellable: Set<AnyCancellable> = Set()
    @Published var pageStatus = PostsPageStatus.ready(nextPage: 1)
    @Published var logEntries = [any ModLogEntry]()
    let communityId: Int
    
    init(communityId: Int) {
        self.communityId = communityId
    }
    
    func fetchLog(apiModel: ApiModel) {
        guard case let .ready(page) = pageStatus else {
            return
        }
        pageStatus = .loading(page: page)
        apiModel.lemmyHttp?.getModlog(communityId: communityId, page: page) { log, _ in
            DispatchQueue.main.async {
                if let log = log {
                    if log.removed_posts.isEmpty && log.banned_from_community.isEmpty && log.removed_comments.isEmpty {
                        self.pageStatus = .done
                    } else {
                        self.logEntries.append(contentsOf: log.removed_posts)
                        self.logEntries.append(contentsOf: log.banned_from_community)
                        self.logEntries.append(contentsOf: log.removed_comments)
                        self.pageStatus = .ready(nextPage: page + 1)
                    }
                } else {
                    self.pageStatus = .failed
                }
            }
        }.store(in: &cancellable)
    }
}
