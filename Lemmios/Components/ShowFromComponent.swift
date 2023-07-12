import CachedAsyncImage
import SwiftUI

struct ShowFromComponent<T: WithNameHost>: View {
    @EnvironmentObject var apiModel: ApiModel
    @State var item: T
    @State var showPlaceholder = false
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default

    var body: some View {
        HStack {
            if let icon = item.icon {
                CachedAsyncImage(url: icon, urlCache: .imageCache, content: { image in
                    image
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 24, height: 24)
                }, placeholder: {
                    ProgressView()
                })
            } else if showPlaceholder {
                Circle()
                    .fill(selectedTheme.secondaryColor)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(item.name.first!.uppercased())
                    }
            }
            if item.local {
                Text(item.name)
                    .lineLimit(1)
            } else {
                let itemHost = item.actor_id.host()!
                Text("\(item.name)\(Text("@\(itemHost)").foregroundColor(.secondary))")
                    .lineLimit(1)
            }
        }
    }
}
