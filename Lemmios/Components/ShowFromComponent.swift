import SwiftUI
import CachedAsyncImage

struct ShowFromComponent<T: WithNameHost>: View {
    @EnvironmentObject var apiModel: ApiModel
    @State var item: T

    var body: some View {
        let itemHost = item.actor_id.host()!
        let apiHost = URL(string: apiModel.url)!.host()!
        HStack {
            if let icon = item.icon {
                CachedAsyncImage(url: icon, content: { image in
                    image
                        .resizable()
                        .clipShape(.circle)
                        .frame(width: 24, height: 24)
                }, placeholder: {
                    ProgressView()
                })
            }
            if itemHost != apiHost {
                Text("\(item.name)\(Text("@\(itemHost)").foregroundColor(.secondary))")
                    .lineLimit(1)
            } else {
                Text(item.name)
                    .lineLimit(1)
            }            
        }
    }
}
