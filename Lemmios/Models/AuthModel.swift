import Combine
import Foundation

class AuthModel: ObservableObject {
    @Published var captcha: LemmyHttp.CaptchaInfo?
    @Published var error = ""
    @Published var verifySent = false
    @Published var needs2fa = false

    private var cancellable = Set<AnyCancellable>()
    private let decoder = JSONDecoder()

    func register(apiModel: ApiModel, info: LemmyHttp.RegisterPayload) {
        apiModel.lemmyHttp?.register(info: info) { response, error in
            if let response = response {
                if let jwt = response.jwt {
                    apiModel.addAuth(username: info.username, jwt: jwt)
                } else if response.verify_email_sent == true {
                    self.verifySent = true
                }
            } else if case let .network(code, description) = error {
                if code == 400, let decoded = try? self.decoder.decode(LemmyHttp.ErrorResponse.self, from: Data(description.utf8)) {
                    self.error = decoded.error
                    self.getCaptcha(apiModel: apiModel)
                }
            }
        }.store(in: &cancellable)
    }

    func login(apiModel: ApiModel, info: LemmyHttp.LoginPayload) {
        apiModel.lemmyHttp?.login(info: info) { response, error in
            if let jwt = response?.jwt {
                apiModel.addAuth(username: info.username_or_email, jwt: jwt)
            } else if case let .network(code, description) = error {
                if code == 400, let decoded = try? self.decoder.decode(LemmyHttp.ErrorResponse.self, from: Data(description.utf8)) {
                    self.error = decoded.error
                    if decoded.error == "missing_totp_token" {
                        self.needs2fa = true
                    }
                }
            }
        }.store(in: &cancellable)
    }

    func getCaptcha(apiModel: ApiModel) {
        apiModel.lemmyHttp?.getCaptcha { response, _ in
            if let response = response {
                DispatchQueue.main.async {
                    self.captcha = response.ok
                }
            }
        }
        .store(in: &cancellable)
    }
}
