import SwiftUI

let defaultServers = ["https://lemmy.world", "https://lemmy.ml", "https://sh.itjust.works", "custom"]

struct ServerSelectorView: View {
    @State var serverUrl = ""
    @State var selected = defaultServers[0]
    @State var errorString = ""
    @EnvironmentObject var apiModel: ApiModel
    var body: some View {
        VStack {
            Text(errorString)
                .foregroundColor(.red)
            Form {
                Section {
                    Picker("Server", selection: $selected) {
                        ForEach(defaultServers, id: \.self) {
                            Text($0)
                        }
                    }
                    if (selected == "custom") {
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
                }
            }
        }
    }
}

struct ServerSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSelectorView()
    }
}
