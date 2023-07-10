import AlertToast
import SwiftUI

struct AuthFormComponent: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @ObservedObject var authModel: AuthModel
    @EnvironmentObject var apiModel: ApiModel
    @Environment(\.dismiss) private var dismiss
    
    @State var selectedTab = AuthType.Login
    @State var showingError = false
    
    @State var username = ""
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    @State var captchaResponse = ""
    @State var totpResponse = ""
    
    var body: some View {
        Form {
            Picker(selection: $selectedTab, label: Text("Auth Type")) {
                ForEach(AuthType.allCases, id: \.id) { tab in
                    Text(tab.rawValue)
                }
            }
            .pickerStyle(.segmented)
            Section {
                TextField("Username", text: $username)
                    .textContentType(.username)
                if case .Signup = selectedTab {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                CustomSecureField(text: $password, label: "Password", errorMessage: nil)
                if case .Signup = selectedTab {
                    CustomSecureField(text: $confirmPassword, label: "Confirm Password", errorMessage: password == confirmPassword ? nil : "Passwords do not match.")
                }
            }
            if authModel.needs2fa {
                Section {
                    TextField("2fa Code", text: $totpResponse)
                        .textContentType(.oneTimeCode)
                }
            }
            if case .Signup = selectedTab, let captcha = authModel.captcha {
                Section {
                    Image(uiImage: UIImage(data: Data(base64Encoded: captcha.png)!)!)
                    Button("Refresh") {
                        authModel.getCaptcha(apiModel: apiModel)
                    }
                    TextField("Captcha Response", text: $captchaResponse)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                }
            }
            Button("Login") {
                if selectedTab == .Login {
                    authModel.login(apiModel: apiModel, info: .init(username_or_email: username, password: password, totp_2fa_token: totpResponse.isEmpty ? nil : totpResponse))
                } else {
                    authModel.register(apiModel: apiModel, info: .init(username: username, password: password, password_verify: confirmPassword, email: email, captcha_answer: captchaResponse, captcha_uuid: authModel.captcha?.uuid ?? UUID().uuidString))
                }
            }
        }
        .listBackgroundModifier(backgroundColor: selectedTheme.backgroundColor)
        .onAppear {
            authModel.needs2fa = false
            self.username = ""
            self.email = ""
            self.password = ""
            self.confirmPassword = ""
            self.captchaResponse = ""
            self.totpResponse = ""
        }
        .onChange(of: apiModel.accounts) { newValue in
            dismiss()
        }
        .onChange(of: authModel.verifySent) { newValue in
            if newValue {
                self.selectedTab = .Login
            }
        }
        .onFirstAppear {
            authModel.getCaptcha(apiModel: apiModel)
        }
        .onChange(of: authModel.error) { newValue in
            if newValue != "" {
                showingError = true
            }
        }
        .toast(isPresenting: $authModel.verifySent, duration: 5) {
            AlertToast(displayMode: .banner(.slide), type: .complete(.green), title: "Verification Email Sent.")
        }
        .toast(isPresenting: $showingError, duration: 5) {
            AlertToast(displayMode: .banner(.slide), type: .error(.red), title: authModel.error.replacingOccurrences(of: "_", with: " ").localizedCapitalized)
        } completion: {
            authModel.error = ""
        }
    }
}

struct CustomSecureField: View {
    @FocusState var focused: focusedField?
    @State var showPassword: Bool = false
    @Binding var text: String
    @State var label: String
    let errorMessage: String?
    
    var body: some View {
        VStack {
            HStack {
                ZStack(alignment: .trailing) {
                    TextField(label, text: $text)
                        .focused($focused, equals: .unSecure)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        // This is needed to remove suggestion bar, otherwise swapping between
                        // fields will change keyboard height and be distracting to user.
                        .keyboardType(.alphabet)
                        .opacity(showPassword ? 1 : 0)
                    SecureField(label, text: $text)
                        .focused($focused, equals: .secure)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .opacity(showPassword ? 0 : 1)
                }
                Button(action: {
                    showPassword.toggle()
                    focused = focused == .secure ? .unSecure : .secure
                }, label: {
                    Image(systemName: self.showPassword ? "eye.slash.fill" : "eye.fill")
                        .padding()
                })
            }
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    // Using the enum makes the code clear as to what field is focused.
    enum focusedField {
        case secure, unSecure
    }
}
