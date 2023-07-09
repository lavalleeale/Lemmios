import SwiftUI

struct AboutView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var apiModel: ApiModel
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
                                .clipShape(.circle)
                                .frame(width: 24, height: 24)
                        }
                    }
                    NavigationLink(value: PostsModel(path: path)) {
                        Label {
                            Text("c/\(path)")
                        } icon: {
                            Image("Icon")
                                .resizable()
                                .clipShape(.circle)
                                .frame(width: 24, height: 24)
                        }
                    }
                    Link(destination: URL(string: "https://github.com/lavalleeale/lemmios")!) {
                        Label {
                            Text("Github")
                        } icon: {
                            Image(uiImage:
                                UIImage(named: colorScheme == .dark ? "github_white.png" : "github_white.png")!
                            )
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        }
                    }
                }
            }
            .scrollDisabled(true)
            Spacer()
        }
        .background(selectedTheme.secondaryColor)
    }
}
