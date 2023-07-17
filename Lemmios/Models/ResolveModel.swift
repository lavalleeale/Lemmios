import Combine
import Foundation
import LemmyApi

class ResolveModel<T: ResolveResponse>: ObservableObject, Hashable {
    private var id = UUID()
    
    static func == (lhs: ResolveModel, rhs: ResolveModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var thing: URL
    
    @Published var value: T?
    
    @Published var error: String?
    
    private var cancellable: AnyCancellable?
    
    func resolve(apiModel: ApiModel) {
        if value == nil {
            cancellable = apiModel.lemmyHttp!.resolveObject(ap_id: thing) { (value: T?, error: LemmyApi.NetworkError?) in
                DispatchQueue.main.async {
                    if let value = value {
                        self.value = value
                    } else {
                        self.error = error?.localizedDescription
                    }
                }
            }
        }
    }
    
    init(thing: URL) {
        self.thing = thing
    }
}
