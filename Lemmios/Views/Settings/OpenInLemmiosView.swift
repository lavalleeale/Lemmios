import AVKit
import Foundation
import SwiftUI

struct OpenInLemmiosView: View {
    var body: some View {
        ColoredListComponent {
            Section {
                PlayerView()
                    .frame(height: 200)
                    .listRowSeparator(.hidden)
                Label("Open the Settings app", systemImage: "gear")
                Label("Select Safari", systemImage: "safari")
                Label("Select Extensions", systemImage: "puzzlepiece.extension")
                Label {
                    Text("Select Open in Lemmios")
                } icon: {
                    Image(uiImage: UIImage(named: "Icon.png")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                Label("Turn On", systemImage: "switch.2")
                Label("Change to \"Allow\" at bottom", systemImage: "checkmark")
            }
            .listRowSeparator(.hidden)
            Section {
                Link("The extension (along with the rest of the app) is open source!", destination: URL(string: "https://github.com/lavalleeale/Lemmios")!)
            }
        }
        .navigationTitle("Open Lemmy Links in Lemmios")
        .navigationBarTitleDisplayMode(.inline)
    }
}
