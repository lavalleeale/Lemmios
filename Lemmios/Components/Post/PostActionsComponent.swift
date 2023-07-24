import SwiftUI
import SwiftUIKit

struct PostActionsComponent: View {
    @ObservedObject var postModel: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @AppStorage("compact") var compact = false
    
    let showCommunity: Bool
    let showUser: Bool
    let collapsedButtons: Bool
    let rowButtons: Bool
    var showInfo = true
    var showArrows = true
    var image = false
    let preview: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if showInfo {
                HStack {
                    if showCommunity {
                        CommunityLink(community: postModel.community!, prefix: {}, suffix: {})
                    }
                    if showUser {
                        UserLink(user: postModel.creator!)
                    }
                }
            }
            HStack {
                if showInfo {
                    DynamicStack(vertical: !compact || !preview) {
                        HStack(spacing: compact && preview ? 0 : nil) {
                            ScoreComponent(votableModel: postModel, preview: preview)
                            Group {
                                HStack(spacing: compact && preview ? 0 : 3) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .scaleEffect(compact && preview ? 0.5 : 0.8)
                                    Text(formatNum(num: postModel.counts!.comments))
                                        .font(compact && preview ? .caption : nil)
                                }
                                HStack(spacing: compact && preview ? 0 : 3) {
                                    Image(systemName: "clock")
                                        .scaleEffect(compact && preview ? 0.5 : 0.8)
                                    Text(postModel.counts!.published.relativeDateAsString())
                                        .font(compact && preview ? .caption : nil)
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                
                }
                if !compact || !preview {
                    Spacer()
                }
                if collapsedButtons {
                    HStack {
                        PostButtons(postModel: postModel, showViewComments: !showInfo, menu: true, showAll: true, image: image)
                            .foregroundStyle(.secondary)
                        if showArrows {
                            ArrowsComponent(votableModel: postModel)
                        }
                    }
                }
                if compact && preview {
                    Spacer()
                }
            }
            if rowButtons {
                Divider()
                HStack {
                    Group {
                        if showArrows {
                            ArrowsComponent(votableModel: postModel)
                        }
                        PostButtons(postModel: postModel, showViewComments: !showInfo, menu: false, showAll: false, image: image)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Divider()
            }
        }
    }
}

struct DynamicStack<Content: View>: View {
    let vertical: Bool
    @ViewBuilder var content: Content
    var body: some View {
        if vertical {
            VStack(alignment: .leading) {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}

struct PostButtons: View {
    @ObservedObject var postModel: PostModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var apiModel: ApiModel
    @State var showingReply = false
    @State var showingReport = false
    @State var reportReason = ""
    @State var showingShare = false
    @State var showingEdit = false
    @State var showingRemind = false
    @State var remindDate = Date()
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    
    var showViewComments: Bool
    var menu: Bool
    var showAll: Bool
    var image = false
    
    var buttons: some View {
        Group {
            if showViewComments {
                PostButton(label: "Comments", image: "bubble.left.and.bubble.right", needsAuth: false) {
                    dismiss()
                    navModel.path.append(postModel)
                }
            }
            PostButton(label: postModel.saved ? "Unsave" : "Save", image: postModel.saved ? "bookmark.fill" : "bookmark") {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                postModel.save(apiModel: apiModel)
            }
            PostButton(label: "Reply", image: "arrowshape.turn.up.left") {
                showingReply = true
            }
            if showAll {
                PostButton(label: "Remind Me...", image: "clock", needsAuth: false) {
                    showingRemind = true
                }
                if let account = apiModel.selectedAccount, let user = postModel.creator, account == user {
                    PostButton(label: postModel.post.deleted ? "Restore" : "Delete", image: postModel.post.deleted ? "trash.slash" : "trash") {
                        postModel.delete(apiModel: apiModel)
                    }
                    PostButton(label: "Edit", image: "pencil") {
                        showingEdit = true
                    }
                } else {
                    if apiModel.moderates?.contains(where: { $0.id == postModel.community?.id }) == true {
                        let removed = postModel.post.removed
                        PostButton(label: removed ? "Restore" : "Remove", image: removed ? "trash.slash" : "trash") {
                            postModel.remove(apiModel: apiModel)
                        }
                    }
                    PostButton(label: "Report", image: "flag") {
                        showingReport = true
                    }
                }
                if let community = postModel.community, let communityHost = community.actor_id.host() {
                    let localCommunity = community.local
                    let communityName = community.name
                    let path = localCommunity ? communityName : "\(communityName)@\(communityHost)"
                    NavigationLink(value: PostsModel(path: path)) {
                        ShowFromComponent(item: community, show: true)
                    }
                }
                if let user = postModel.creator {
                    NavigationLink(value: UserModel(user: user)) {
                        ShowFromComponent(item: user, show: true)
                    }
                }
                Button { showingShare = true } label: {
                    Label {
                        Text("Share as Image")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(.all, 10)
                    }
                }
            }
            Button {
                if image {
                    URLSession.shared.dataTask(with: postModel.post.UrlData!) { data, _, _ in
                        guard let data = data,
                              let image = UIImage(data: data)
                        else { return }
                        
                        DispatchQueue.main.async {
                            alwaysShare(item: ItemDetailSource(name: postModel.post.name, image: image))
                        }
                    }.resume()
                } else {
                    alwaysShare(item: postModel.post.ap_id)
                }
            } label: {
                Label {
                    Text("Share")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .padding(.all, 10)
                }
            }
            .foregroundStyle(.secondary)
        }
    }
    
    var body: some View {
        Group {
            if menu {
                Menu {
                    buttons
                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            } else {
                buttons
                    .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $showingRemind) {
            if #available(iOS 16.4, *) {
                sheet.presentationBackground(selectedTheme.secondaryColor)
            } else {
            sheet
            }
        }
        .overlay {
            PostSharePreview(postModel: postModel, isPresented: $showingShare, comments: [])
        }
        .sheet(isPresented: $showingEdit) {
            PostCreateComponent(title: postModel.post.name, postData: postModel.post.body ?? "", postUrl: postModel.post.UrlData?.absoluteString ?? "", dataModel: postModel)
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet(title: "Add Comment") { commentBody in
                postModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
        .alert("Report", isPresented: $showingReport) {
            TextField("Reason", text: $reportReason)
            Button("OK") {
                postModel.report(reason: reportReason, apiModel: apiModel)
                showingReport = false
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    var sheet: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $remindDate)
                Button("Submit", action: addReminder)
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingRemind = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", action: addReminder)
                }
            }
        }
        .foregroundColor(nil)
    }
    
    func addReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Reminder for \(postModel.post.name)"
        content.body = "\(postModel.post.ap_id)"
        // Configure the recurring date.
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindDate)
        
        // Create the trigger as a repeating event.
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: trigger)
        
        // Schedule the request with the system.
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if error != nil {
                return
            }
            
            if granted {
                center.add(request) { _ in}
            }
            self.showingRemind = false
        }
    }
}

struct PostButton: View {
    @EnvironmentObject var apiModel: ApiModel
    
    let label: String
    let image: String
    var needsAuth = true
    let action: () -> Void
    
    var body: some View {
        Button {
            if needsAuth && apiModel.selectedAccount == nil {
                apiModel.getAuth()
            } else {
                action()
            }
        } label: {
            Label {
                Text(label)
            } icon: {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(.all, 10)
            }
        }
        .foregroundStyle(.secondary)
    }
}
