import Foundation
import LemmyApi
import UserNotifications

class RemindersModel: ObservableObject {
    @Published var requests = [Reminder]()
    private var center = UNUserNotificationCenter.current()
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()

    init() {
        getReminders()
    }
    
    func getReminders() {
        self.requests.removeAll()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                DispatchQueue.main.async {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger, let date = Calendar.current.date(from: trigger.dateComponents) {
                        let data = try! JSONSerialization.data(withJSONObject: request.content.userInfo)
                        if let postData = try? self.decoder.decode(LemmyApi.ApiPostData.self, from: data) {
                            self.requests.append(Reminder(date: date, data: .post(data: postData), id: request.identifier))
                        } else if let commentData = try? self.decoder.decode(LemmyApi.ApiComment.self, from: data) {
                            self.requests.append(Reminder(date: date, data: .comment(data: commentData), id: request.identifier))
                        }
                    }
                }
            }
        })
    }
    
    func remove(_ reminder: Reminder) {
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id])
        getReminders()
    }
}

struct Reminder {
    let date: Date
    let data: ReminderData
    let id: String
    enum ReminderData {
        case post(data: LemmyApi.ApiPostData), comment(data: LemmyApi.ApiComment)
    }
}

