import LemmyApi
import MarkdownUI
import SwiftUI
import SwiftUIKit

let colors = [Color.green, Color.red, Color.orange, Color.yellow]

struct CommentComponent: View {
    @Environment(\.redactionReasons) private var reasons
    @EnvironmentObject var parent: CommentModel
    @StateObject var commentModel: CommentModel

    @State var collapsed = false

    @State var preview = false

    @State var showingReply = false

    @State var showingEdit = false

    @State var showingReport = false
    @State var reportReason = ""

    @State var showingRemind = false
    @State var remindDate = Date()

    @State var showingBan = false
    @State var banReason = ""
    @State var banDays = ""

    @State var showingNuke = false

    var replyInfo: LemmyApi.CommentReply?

    @EnvironmentObject var post: PostModel
    @EnvironmentObject var apiModel: ApiModel
    @EnvironmentObject var navModel: NavModel
    @EnvironmentObject var postModel: PostModel
    @AppStorage("commentImages") var commentImages = true
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default

    let depth: Int

    var read: (() -> Void)?

    let collapseParent: (() -> Void)?

    var share: ((Int) -> Void)?

    var menuButtons: some View {
        Group {
            if let account = apiModel.selectedAccount, account == commentModel.comment.creator {
                if apiModel.moderates?.contains(where: { $0.id == commentModel.comment.community.id }) == true {
                    let distinguished = commentModel.comment.comment.distinguished
                    PostButton(label: distinguished ? "Undistinguish" : "Distinguish as Moderator", image: distinguished ? "shield.slash" : "shield") {
                        commentModel.distinguish(apiModel: apiModel)
                    }
                }
                PostButton(label: "Edit", image: "pencil") {
                    showingEdit = true
                }
                let deleted = commentModel.comment.comment.deleted
                PostButton(label: deleted ? "Restore" : "Delete", image: deleted ? "trash.slash" : "trash") {
                    commentModel.delete(apiModel: apiModel)
                }
            } else {
                if apiModel.moderates?.contains(where: { $0.id == commentModel.comment.community.id }) == true {
                    let removed = commentModel.comment.comment.removed
                    PostButton(label: removed ? "Restore" : "Remove", image: removed ? "trash.slash" : "trash") {
                        commentModel.remove(apiModel: apiModel)
                    }
                    if !removed {
                        PostButton(label: "Nuke", image: "trash") {
                            showingNuke = true
                        }
                    }
                    let banned = commentModel.creator_banned_from_community
                    PostButton(label: banned ? "Unabn from community" : "Ban from community", image: "") {
                        if banned {
                            commentModel.ban(reason: "", remove: false, expires: nil, apiModel: apiModel)
                        } else {
                            showingBan = true
                            banReason = ""
                            banDays = ""
                        }
                    }
                }
                PostButton(label: "Report", image: "flag") {
                    showingReport = true
                }
            }
            let user = commentModel.comment.creator
            NavigationLink(value: UserModel(user: commentModel.comment.creator)) {
                ShowFromComponent(item: user, show: true)
            }
            PostButton(label: "Remind Me...", image: "clock", needsAuth: false) {
                showingRemind = true
            }
            PostButton(label: "Share as Image", image: "square.and.arrow.up", needsAuth: false) {
                share?(commentModel.comment.id)
            }
            ShareLink(item: commentModel.comment.comment.ap_id) {
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
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        UserLink(user: commentModel.comment.creator)
                            .accessibility(identifier: "\(commentModel.comment.creator.name) user button")
                            .foregroundColor(commentModel.comment.comment.distinguished ? Color.green : commentModel.comment.creator.id == commentModel.comment.post.creator_id ? Color.blue : Color.primary)
                        ScoreComponent(votableModel: commentModel)
                        Spacer()
                        if !reasons.contains(.screenshot) {
                            Menu { menuButtons } label: {
                                Label {
                                    Text("Comment Options")
                                } icon: {
                                    Image(systemName: "ellipsis")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }
                                .labelStyle(.iconOnly)
                            }
                            .foregroundStyle(.secondary)
                            .highPriorityGesture(TapGesture())
                        }
                        Text(commentModel.comment.counts.published.relativeDateAsString())
                            .foregroundStyle(.secondary)
                        if replyInfo != nil {
                            Image(systemName: replyInfo!.read ? "envelope.open" : "envelope.badge")
                                .symbolRenderingMode(.multicolor)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .redacted(reason: .privacy)
                    if !collapsed {
                        if commentModel.comment.comment.deleted {
                            Text("deleted by creator")
                                .italic()
                        } else if commentModel.comment.comment.removed {
                            Text("removed by mod")
                                .italic()
                        } else {
                            MarkdownView(processMarkdown(input: commentModel.comment.comment.content, stripImages: !commentImages), baseURL: URL(string: apiModel.url)!)
                        }
                    }
                }
                .contentShape(Rectangle())
                .commentDepthIndicator(depth: depth)
                .padding(.top, 10)
                Spacer()
                    .frame(height: 10)
            }
            .onChange(of: parent.nuked) { newValue in
                if newValue {
                    parent.nuked = false
                    commentModel.nuked = true
                    commentModel.comment.comment.removed = true
                }
            }
            .onTapGesture {
                if preview {
                    if let replyInfo = replyInfo, replyInfo.read == false {
                        commentModel.read(replyInfo: replyInfo, apiModel: apiModel) {
                            read!()
                        }
                    }
                    navModel.path.append(PostModel(post: commentModel.comment.post, comment: commentModel.comment.comment))
                } else {
                    withAnimation {
                        collapsed.toggle()
                    }
                }
            }
            .padding(.horizontal)
            .if(!reasons.contains(.screenshot)) { view in
                view
                    .addSwipe(leadingOptions: [
                        SwipeOption(id: "upvote", image: "arrow.up", color: .orange),
                        SwipeOption(id: "downvote", image: "arrow.down", color: .purple)
                    ],
                    trailingOptions: [
                        replyInfo != nil ? SwipeOption(id: "read", image: replyInfo!.read ? "envelope.badge" : "envelope.open", color: Color(hex: "3880EF")!) : SwipeOption(id: "collapse", image: "arrow.up.to.line", color: Color(hex: "3880EF")!),
                        SwipeOption(id: "reply", image: "arrowshape.turn.up.left", color: .blue)
                    ]) { swiped in
                        switch swiped {
                        case "upvote":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                commentModel.vote(direction: true, apiModel: apiModel)
                            }
                        case "downvote":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                commentModel.vote(direction: false, apiModel: apiModel)
                            }
                        case "reply":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                showingReply = true
                            }
                        case "read":
                            if apiModel.selectedAccount == nil {
                                apiModel.getAuth()
                            } else {
                                commentModel.read(replyInfo: replyInfo!, apiModel: apiModel) {
                                    read!()
                                }
                            }
                        case "collapse":
                            withAnimation {
                                if let collapseParent = collapseParent {
                                    collapseParent()
                                } else {
                                    self.collapsed = true
                                }
                            }
                            return
                        default:
                            break
                        }
                    }
            }
            .contextMenu { menuButtons }
            .overlay {
                Color.gray.opacity(!preview && postModel.selectedCommentPath?.components(separatedBy: ".").last == String(commentModel.comment.id) ? 0.3 : 0)
                    .allowsHitTesting(false)
            }
            if commentModel.comment.counts.child_count != 0 && commentModel.children.isEmpty && !preview {
                Divider()
                    .padding(.leading, CGFloat(depth + 1) * 10)
                HStack {
                    Button {
                        commentModel.fetchComments(apiModel: apiModel, postModel: postModel)
                    } label: {
                        if case .loading = commentModel.pageStatus {
                            ProgressView()
                        } else {
                            Text("Show \(commentModel.comment.counts.child_count) More")
                        }
                    }
                    .frame(height: 30, alignment: .leading)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .commentDepthIndicator(depth: depth + 1)
            }
            LazyVStack(spacing: 0) {
                let directChildren = commentModel.children.filter { isCommentParent(parentId: commentModel.comment.id, possibleChild: $0) }
                ForEach(directChildren) { comment in
                    Divider()
                        .padding(.leading, CGFloat(depth + 1) * 10)
                    CommentComponent(commentModel: CommentModel(comment: comment, children: commentModel.children.filter { $0.comment.path.contains("\(comment.id).") }), depth: depth + 1, collapseParent: {
                        if collapseParent != nil {
                            collapseParent!()
                        } else {
                            self.collapsed = true
                        }
                    }, share: share)
                        .environmentObject(commentModel)
                }
            }
            .allowsHitTesting(!collapsed)
            .frame(maxHeight: commentModel.children.isEmpty || collapsed ? 0 : .infinity)
            .clipped()
        }
        .alert("Report", isPresented: $showingReport) {
            TextField("Reason", text: $reportReason)
            Button("OK") {
                commentModel.report(reason: reportReason, apiModel: apiModel)
                showingReport = false
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingReply) {
            CommentSheet(title: "Add Comment") { commentBody in
                commentModel.comment(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
        .sheet(isPresented: $showingEdit) {
            CommentSheet(commentBody: commentModel.comment.comment.content, title: "Edit Comment") { commentBody in
                commentModel.edit(body: commentBody, apiModel: apiModel)
            }
            .presentationDetent([.fraction(0.4), .large], largestUndimmed: .fraction(0.4))
        }
        .sheet(isPresented: $showingRemind) {
            if #available(iOS 16.4, *) {
                sheet.presentationBackground(selectedTheme.secondaryColor)
            } else {
                sheet
            }
        }
        .alert("Ban", isPresented: $showingBan) {
            TextField("Reason", text: $banReason)
            TextField("Ban Length (days) (optional)", text: $banDays)
                .keyboardType(.numberPad)
            Button("Ban", role: .destructive) {
                if let banDays = Int(banDays) {
                    commentModel.ban(reason: banReason, remove: false, expires: Int(Date.now.timeIntervalSince1970) + banDays * 24 * 60 * 60, apiModel: apiModel)
                } else {
                    commentModel.ban(reason: banReason, remove: false, expires: nil, apiModel: apiModel)
                }
            }
            Button("Ban and remove content", role: .destructive) {
                if let banDays = Int(banDays) {
                    commentModel.ban(reason: banReason, remove: true, expires: Int(Date.now.timeIntervalSince1970) + banDays * 24 * 60 * 60, apiModel: apiModel)
                } else {
                    commentModel.ban(reason: banReason, remove: false, expires: nil, apiModel: apiModel)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Nuke", isPresented: $showingNuke) {
            Button("Cancel", role: .cancel) {}
            Button("Nuke", role: .destructive) {
                commentModel.nuke(apiModel: apiModel)
            }
        } message: {
            Text("Nuking will delete comment and all (loaded) childern")
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
        content.body = "\(commentModel.comment.comment.ap_id)"
        content.userInfo = commentModel.comment.dictionary
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
                center.add(request) { _ in }
            }
            self.showingRemind = false
        }
    }
}

public extension RedactionReasons {
    static let screenshot = RedactionReasons(rawValue: 1 << 10)
}
