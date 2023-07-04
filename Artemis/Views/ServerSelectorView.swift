import SwiftUI

struct ServerSelectorView: View {
    @State var serverUrl = ""
    @State var errorString = ""
    @EnvironmentObject var apiModel: ApiModel
    var body: some View {
        VStack {
            Text(errorString)
                .foregroundColor(.red)
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
}

struct ServerSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSelectorView()
    }
}
