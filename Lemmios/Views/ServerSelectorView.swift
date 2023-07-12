import SwiftUI

struct ServerSelectorView: View {
    @State var serverUrl = ""
    @State var selected = ""
    @State var errorString = ""
    @EnvironmentObject var apiModel: ApiModel
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("serverUrl") public var url = ""
    @AppStorage("servers") var defaultServers = ["https://lemmy.world", "https://lemmy.ml", "https://sh.itjust.works", "custom"]

    @State var needsForm = true
    
    var callback: (() -> Void)? = nil

    var body: some View {
        Group {
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
            HStack(spacing: 0) {
                NavigationLink("By selecting a server you agree to Lemmios's terms of use") {
                    ScrollView {
                        Text("""
                        Welcome to Lemmios! Before you proceed, please carefully read and agree to the following Terms of Service (\"Terms\") governing your use of our app. By accessing or using Lemmios, you acknowledge that you have read, understood, and agreed to be bound by these Terms. If you do not agree with any part of these Terms, please refrain from using our app.
                        
                                                 1. User Responsibilities
                                                    
                                                 1.1 Reporting Content: Lemmios encourages users to report any content they find questionable or in violation of the Lemmy instance's rules and guidelines. You may report such content to the moderators of the Lemmy instance you are using, either within Lemmios or through the reporting mechanisms provided by the instance. We are not responsible for moderating or enforcing Lemmy instance rules, but we encourage you to help maintain a positive and respectful community by reporting objectionable content.
                                                    
                                                 1.2 Blocking Users and Instances: Lemmios provides users with the ability to block individual users or entire communities that they find questionable or wish to avoid. This feature empowers you to customize your Lemmios experience and enhance your interactions within the app. We encourage you to use these blocking features as needed to create a safe and enjoyable environment for yourself.
                                                    
                                                 1.3 Following Rules of Instances: Lemmios encourages all users to follow the rules of the instance they are using. The terms of your instance can be found on the website for your instance. Failure to comply with all the rules of your instance will result in termination of your account with that instance.
                                                    
                                                 1.4 No Misuse: The misuse of Lemmios will result in termination of all services - to the furthest of our ability - with us. We reserve the right to terminate - to the furthest of our ability - all services that you use including push notifications and instance searching.
                                                    
                                                 1.5 No Abusive, Unlawful, or Offensive Content: You agree that you will not use Lemmios to produce any abusive or offensive content. This includes, but is not limited to: content that is unlawful, harmful, threatening, abusive, harassing, tortious, defamatory, vulgar, obscene, libelous, invasive, hateful, or racially, ethnically, or otherwise objectionable. The content you produce will not harm minors in any way. You will not impersonate any person or entity. You will not upload or post any content that you do not have the right to make available under any US or foreign laws. You will not produce content that interferes with or disrupts the app, the Lemmy instances that you use, other Lemmy instances, or any other service or person. You will not transmit misinformation in any capacity to any individual.
                                                    
                                                 2. Limitation of Liability
                                                    
                                                 2.1 No Liability: To the fullest extent permitted by applicable law, we disclaim any liability for any direct, indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, arising from your use of Lemmios or any interactions within the Lemmy instances. This includes, but is not limited to, any damages resulting from the content, actions, or conduct of other users or the Lemmy instances.
                                                    
                                                 3. General Provisions
                                                    
                                                 3.1 Modifications: We reserve the right to modify, suspend, or terminate Lemmios or these Terms, at our sole discretion, at any time and without prior notice. Your continued use of Lemmios after any modifications to these Terms shall constitute your acceptance of the modified Terms.
                                                    
                                                 3.2 Governing Law: These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to its conflict of laws principles.
                                                    
                                                 3.3 Entire Agreement: These Terms constitute the entire agreement between you and us regarding your use of Lemmios and supersede any prior or contemporaneous agreements, communications, or proposals, whether oral or written, between you and us.
                                                    
                                                 By using Lemmios, you affirm that you have read, understood, and agreed to these revised Terms of Service. If you have any questions or concerns, please contact us at alex@lavallee.one. Thank you for using Lemmios!
                        """)
                    }
                }
                .foregroundColor(.accentColor)
            }
            Button("Submit") {
                errorString = apiModel.selectServer(url: selected == "custom" ? serverUrl : selected)
                if errorString == "" {
                    if !defaultServers.contains(apiModel.url) {
                        defaultServers.insert(apiModel.url, at: defaultServers.count - 1)
                    }
                    callback?()
                }
            }
        }.if(needsForm) { view in
            Form {
                view
            }
            .listBackgroundModifier(backgroundColor: selectedTheme.secondaryColor)
        }
        .navigationTitle("Server Selector")
        .navigationBarTitleDisplayMode(.inline)
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
