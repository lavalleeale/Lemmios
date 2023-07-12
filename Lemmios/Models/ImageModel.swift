import Foundation
import PhotosUI
import SwiftUI

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

class ImageModel: ObservableObject {
    @Published var imageState = ImageState.empty
    
    func setImage(imageSelection: PhotosPickerItem?, apiModel: ApiModel) {
        if let imageSelection {
            let progress = loadTransferable(from: imageSelection, apiModel: apiModel)
            imageState = .loading(progress)
        } else {
            imageState = .empty
        }
    }
    
    func delete(apiModel: ApiModel) {
        if case let .success(file, _) = imageState {
            apiModel.lemmyHttp!.deletePhoto(data: file)
            imageState = .empty
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem, apiModel: ApiModel) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileImage?):
                    apiModel.lemmyHttp!.uploadPhoto(data: profileImage.data, mimeType: profileImage.mimeType) { percentDone in
                        DispatchQueue.main.async {
                            self.imageState = .uploading(percentDone, profileImage.image)
                        }
                    } doneCallback: { url, error in
                        DispatchQueue.main.async {
                            if let url = url {
                                print(1)
                                self.imageState = .success(url.files[0], profileImage.image)
                            } else if case .network(let code, _) = error {
                                print("test")
                                if code == 413 {
                                    self.imageState = .failure(.tooLarge)
                                } else {
                                    self.imageState = .failure(.unknown)
                                }
                            }
                        }
                    }
                    self.imageState = .uploading(0, profileImage.image)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(.loadingImage)
                }
            }
        }
    }
    
    struct ProfileImage: Transferable {
        let image: Image
        let data: Data
        
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                #if canImport(AppKit)
                    guard let nsImage = NSImage(data: data) else {
                        throw TransferError.importFailed
                    }
                    let image = Image(nsImage: nsImage)
                    return ProfileImage(image: image, data: data)
                #elseif canImport(UIKit)
                    guard let uiImage = UIImage(data: data) else {
                        throw TransferError.importFailed
                    }
                    let image = Image(uiImage: uiImage)
                    return ProfileImage(image: image, data: data)
                #else
                    throw TransferError.importFailed
                #endif
            }
        }
        
        var mimeType: String {
            var b: UInt8 = 0
            data.copyBytes(to: &b, count: 1)

            switch b {
            case 0xff:
                return "image/jpeg"
            case 0x89:
                return "image/png"
            case 0x47:
                return "image/gif"
            case 0x4d, 0x49:
                return "image/tiff"
            case 0x25:
                return "application/pdf"
            case 0xd0:
                return "application/vnd"
            case 0x46:
                return "text/plain"
            default:
                return "application/octet-stream"
            }
        }
    }
    
    enum ImageError: String {
        case loadingImage = "Error while loading image", tooLarge = "Image too large", unknown = "Unkown image error"
    }
    
    enum ImageState: Equatable {
        var isError: Bool {
            if case .failure = self {
                return true
            }
            return false
        }
        case empty, loading(_ progress: Progress), uploading(_ percentDone: Double, _ image: Image), success(_ url: LemmyHttp.File, _ image: Image), failure(_ error: ImageError)
    }
    
    enum TransferError: Error {
        case importFailed
    }
}
