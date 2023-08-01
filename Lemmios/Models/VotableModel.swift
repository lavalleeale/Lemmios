import Foundation

protocol VotableModel: ObservableObject {
    var score: Int {get set}
    var upvotes: Int {get set}
    var downvotes: Int {get set}
    var likes: Int {get set}
    func vote(direction: Bool, apiModel: ApiModel)
}
