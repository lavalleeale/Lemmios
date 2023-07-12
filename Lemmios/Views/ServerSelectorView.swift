import SwiftUI

let defaultServers = ["https://lemmy.world", "https://lemmy.ml", "https://sh.itjust.works", "custom"]

struct ServerSelectorView: View {
    @State var serverUrl = ""
    @State var selected = ""
    @State var errorString = ""
    @EnvironmentObject var apiModel: ApiModel
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("serverUrl") public var url = ""

    init(callback: (() -> Void)? = nil) {
        self.callback = callback
    }

    let callback: (() -> Void)?

    var body: some View {
        Form {
            if errorString != "" {
                Text(errorString)
                    .foregroundColor(.red)
            }
            Section {
                Picker("Server", selection: $selected) {
                    ForEach(defaultServers, id: \.self) {
                        Text($0)
                    }
                }
                if selected == "custom" {
                    TextField("Server URL", text: $serverUrl)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                        .autocorrectionDisabled(true)
                        .onSubmit {
                            errorString = apiModel.selectServer(url: serverUrl)
                        }
                        .padding()
                }
            }
            Button("Submit") {
                errorString = apiModel.selectServer(url: selected == "custom" ? serverUrl : selected)
                if errorString == "" {
                    callback?()
                }
            }
        }
        .navigationTitle("test")
        .navigationBarTitleDisplayMode(.inline)
        .listBackgroundModifier(backgroundColor: selectedTheme.secondaryColor)
        .onAppear {
            if url == "" {
                self.selected = defaultServers[0]
            } else if defaultServers.contains(url) {
                self.selected = url
            } else {
                self.selected = "custom"
                self.serverUrl = url
            }
        }
    }
}

struct ServerSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSelectorView()
    }
}
