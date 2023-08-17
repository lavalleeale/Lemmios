import LemmyApi
import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var apiModel: ApiModel
    @StateObject var reportsModel: ReportsModel
    var body: some View {
        let allReports: [any ReportView] = reportsModel.comments + reportsModel.posts
        ColoredListComponent {
            Toggle("Show Resolved", isOn: $reportsModel.showResolved)
                .onChange(of: reportsModel.showResolved) { _ in
                    reportsModel.refresh(apiModel: apiModel)
                }
            ForEach(allReports.sorted { $0.published > $1.published }, id: \.id) { report in
                VStack {
                    if let report = report as? LemmyApi.CommentReportView {
                        let model = CommentModel(comment: report.commentView, children: [])
                        CommentComponent(parent: model, commentModel: model, preview: true, depth: 0, collapseParent: nil)
                            .onAppear {
                                if report.id == reportsModel.comments.last?.id {
                                    reportsModel.fetchComments(apiModel: apiModel)
                                }
                            }
                    } else if let report = report as? LemmyApi.PostReportView {
                        PostPreviewComponent(post: report.postView, showCommunity: true, showUser: true)
                            .onAppear {
                                if report.id == reportsModel.posts.last?.id {
                                    reportsModel.fetchPosts(apiModel: apiModel)
                                }
                            }
                    }
                    HStack {
                        Text("Reported by")
                        UserLink(user: report.reporter)
                        Text("for \(report.reason)")
                        Spacer()
                        Text(report.published.relativeDateAsString())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    if let resolver = report.resolver {
                        HStack {
                            Text("\(report.resolved ? "Resolved" : "Unresolved") by")
                            UserLink(user: resolver)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .environment(\.reportInfo, report)
                .padding(.bottom)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            if case .loading = reportsModel.postsStatus {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if case .loading = reportsModel.commentsStatus {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if case .done = reportsModel.postsStatus, case .done = reportsModel.commentsStatus {
                Text("No more reports!")
            }
        }
        .refreshable {
            reportsModel.refresh(apiModel: apiModel)
        }
        .listStyle(.plain)
        .onAppear {
            if reportsModel.comments.isEmpty, reportsModel.posts.isEmpty {
                reportsModel.fetchPosts(apiModel: apiModel)
                reportsModel.fetchComments(apiModel: apiModel)
            }
        }
    }
}
