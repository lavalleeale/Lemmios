import Foundation

extension LemmyHttp {
    func deletePhoto(data: File) {
        var request = URLRequest(url: URL(string: "\(self.baseUrl)/pictrs/image/delete/\(data.delete_token)/\(data.file)")!)
        URLSession.shared.dataTask(with: request).resume()
    }
    func uploadPhoto(data: Data, mimeType: String, callback: @escaping (Double)->Void, doneCallback: @escaping(PictrsResponse?, LemmyHttp.NetworkError?)->Void) {
        let delegate = UploadDelegate(callback: callback)
        Task {
            var request = URLRequest(url: URL(string: "\(self.baseUrl)/pictrs/image")!)

            request.httpMethod = "POST"
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("jwt=\(jwt!)", forHTTPHeaderField: "cookie")
            let fieldData = NSMutableData()

            fieldData.append("--\(boundary)\r\n")
            fieldData.append("Content-Disposition: form-data; name=\"images[]\"; filename=\"test.png\"\r\n")
            fieldData.append("Content-Type: \(mimeType)\r\n")
            fieldData.append("\r\n")
            fieldData.append(data)
            fieldData.append("\r\n")
            fieldData.append("--\(boundary)--\r\n")
            let (data, response) = try await URLSession.shared.upload(for: request, from: fieldData as Data, delegate: delegate)
            if let response = (response as? HTTPURLResponse) {
                if response.statusCode != 201 {
                    doneCallback(nil, .network(code: response.statusCode, description: String(data: data, encoding: .utf8) ?? ""))
                } else {
                    do {
                        let  decoded = try JSONDecoder().decode(PictrsResponse.self, from: data)
                        doneCallback(decoded, nil)
                    } catch let error {
                        doneCallback(nil, .decoding(message: String(data: data, encoding: .utf8) ?? "", error: error as! DecodingError))
                    }
                }
            } else {
                doneCallback(nil, .network(code: 0, description: "Response was not HTTPURLResponse?"))
            }
        }
    }
    struct PictrsResponse: Codable {
        let msg: String
        let files: [File]
    }
    
    struct File: Codable, Equatable {
        let file: String
        let delete_token: String
    }
}

class UploadDelegate: NSObject, URLSessionTaskDelegate {
    let callback: (Double) -> Void
    
    init(callback: @escaping (Double) -> Void) {
        self.callback = callback
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        callback(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    }
}

extension NSMutableData {
    func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
