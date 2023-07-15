import Foundation
import SQLite
import SwiftUI

class DBModel {
    private var db: Connection
    let readPosts = Table("readPosts")
    let id = Expression<Int>("id")
    static var instance = DBModel()
    init() {
        let dbUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("read.db")
        db = try! Connection(dbUrl.absoluteString)
        try? db.run(readPosts.create { t in
            t.column(id, primaryKey: true)
        })
    }

    func isRead(postId: Int) -> Bool {
        return try! db.scalar(readPosts.filter(id == postId).count) == 1
    }

    func read(postId: Int) {
        _ = try? db.run(readPosts.insert(id <- postId))
    }

    func clear() {
        _ = try? db.run(readPosts.delete())
    }
}
