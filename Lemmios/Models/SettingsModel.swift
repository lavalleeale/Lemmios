import Foundation
import Combine

class SettingsModel: ObservableObject {
    @Published var deleteResponse: Bool?
    @Published var deleteError: String?
    private var deleteCancellable = Set<AnyCancellable>()
    
    func deleteAccount(password: String, apiModel: ApiModel) {
        apiModel.lemmyHttp!.deleteAccount(password: password) { deleteResponse, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.deleteResponse = false
                    if case .lemmyError(message: let message, code: _) = error {
                        self.deleteError = String(message.components(separatedBy: "_").joined(separator: " ")).localizedCapitalized
                    }
                } else {
                    self.deleteResponse = true
                    apiModel.deleteAuth(account: apiModel.selectedAccount!)
                }
            }
        }.store(in: &deleteCancellable)
    }
}
