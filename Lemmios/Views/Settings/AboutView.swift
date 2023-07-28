import OSLog
import SwiftUI

struct AboutView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var apiModel: ApiModel
    @State var collecting = false

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                Image(uiImage: UIImage(named: "Icon.png")!)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading) {
                    Text("Lemmios \(Bundle.main.releaseVersionNumber!).\(Bundle.main.buildVersionNumber!)")
                    Text("by Alexander Lavallee")
                        .foregroundStyle(.secondary)
                }
                .font(.title3)
            }
            ColoredListComponent {
                if let url = URL(string: apiModel.url), let host = url.host() {
                    let path = host == "lemmy.world" ? "lemmiosapp" : "lemmiosapp@lemmy.world"
                    let userPath = host == "lemmy.world" ? "mrlavallee" : "mrlavallee@lemmy.world"
                    NavigationLink(value: UserModel(path: userPath)) {
                        Label {
                            Text("u/\(userPath)")
                        } icon: {
                            Image("mrlavallee")
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 24, height: 24)
                        }
                    }
                    NavigationLink(value: PostsModel(path: path)) {
                        Label {
                            Text("c/\(path)")
                        } icon: {
                            Image("AppIcon-Preivew")
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 24, height: 24)
                        }
                    }
                    Link(destination: URL(string: "https://github.com/lavalleeale/lemmios")!) {
                        Label {
                            Text("Github")
                        } icon: {
                            Image(colorScheme == .dark ? "github_white" : "github_white")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    .foregroundStyle(.primary)
                    Button {
                        self.collecting = true
                        DispatchQueue.global(qos: .userInteractive).async {
                            if let logStore = try? OSLogStore(scope: .currentProcessIdentifier), let entries = try? logStore.getEntries(at: logStore.position(timeIntervalSinceLatestBoot: 1)), let encoded = try? String(data: JSONEncoder().encode(entries.map { $0.composedMessage }), encoding: .utf8), collecting {
                                DispatchQueue.main.async {
                                    collecting = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    let activityVC = UIActivityViewController(activityItems: [encoded], applicationActivities: nil)
                                    UIApplication.shared.currentUIWindow()?.rootViewController?
                                        .present(activityVC, animated: true, completion: nil)
                                }
                            }
                        }
                    } label: {
                        Label("Get Logs", systemImage: "doc.text")
                    }
                    .foregroundStyle(.primary)
                }
            }
            .scrollDisabled(true)
            Spacer()
        }
        .alert("Collecting Logs", isPresented: $collecting) {
            Button("Cancel", role: .cancel) {}
        }
        .background(selectedTheme.secondaryColor)
    }
}
