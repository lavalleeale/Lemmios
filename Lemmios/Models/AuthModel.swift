import Combine
import Foundation
import LemmyApi

class AuthModel: ObservableObject {
    @Published var captcha: LemmyApi.CaptchaInfo?
    @Published var error = ""
    @Published var verifySent = false
    @Published var needs2fa = false

    private var cancellable = Set<AnyCancellable>()
    private let decoder = JSONDecoder()

    func register(apiModel: ApiModel, info: LemmyApi.RegisterPayload) {
        apiModel.lemmyHttp?.register(info: info) { response, error in
            if let response = response {
                if let jwt = response.jwt {
                    apiModel.addAuth(username: info.username, jwt: jwt)
                } else if response.verify_email_sent == true {
                    self.verifySent = true
                }
            } else if case let .lemmyError(message, code) = error {
                if code == 400 {
                    self.error = message
                    self.getCaptcha(apiModel: apiModel)
                }
            }
        }.store(in: &cancellable)
    }

    func login(apiModel: ApiModel, info: LemmyApi.LoginPayload) {
        apiModel.lemmyHttp?.login(info: info) { response, error in
            if let jwt = response?.jwt {
                apiModel.addAuth(username: info.username_or_email, jwt: jwt)
            } else if case let .lemmyError(message, code) = error {
                self.error = message
                if message == "missing_totp_token" {
                    self.needs2fa = true
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
