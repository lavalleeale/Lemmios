import SwiftUI

struct SettingViewComponent<T>: View where T: RawRepresentable, T.RawValue == String {
    @State private var showingOptions = false
    @Binding var selection: T
    let desciption: String
    let options: [T]

    var body: some View {
        Button {
            showingOptions = true
        } label: {
            HStack {
                Text(desciption)
                Spacer()
                Text(selection.rawValue)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .confirmationDialog("\(desciption)...", isPresented: $showingOptions, titleVisibility: .visible) {
            ForEach(options, id: \.rawValue) { option in
                Button(option.rawValue) {
                    selection = option
                }
            }
        }
    }
}
