import SwiftUI

struct IconsView: View {
    @ObservedObject var iconsModel = IconsModel()
    var body: some View {
        ColoredListComponent {
            ForEach(IconsModel.AppIcon.allCases) { icon in
                HStack {
                    icon.preview
                    Text(icon.description)
                    Spacer()
                    if iconsModel.selectedAppIcon == icon {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        iconsModel.updateAppIcon(to: icon)
                    }
                }
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IconsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            IconsView()
        }
    }
}
