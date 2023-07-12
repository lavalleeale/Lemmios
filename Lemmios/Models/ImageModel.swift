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
    
    func setImage(imageSelection: PhotosPickerItem?, targetSize: Int, apiModel: ApiModel) {
        if let imageSelection {
            let progress = loadTransferable(from: imageSelection, targetSize: targetSize, apiModel: apiModel)
            imageState = .loading(progress)
        } else {
            imageState = .empty
        }
    }
    
    func delete(apiModel: ApiModel) {
        if case .success(let file, _) = imageState {
            apiModel.lemmyHttp!.deletePhoto(data: file)
            imageState = .empty
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem, targetSize: Int, apiModel: ApiModel) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileImage?):
                    self.loadImage(profileImage.image, targetSize: targetSize, apiModel: apiModel)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(.loadingImage, nil)
                }
            }
        }
    }
    
    func loadImage(_ image: UIImage, targetSize: Int, apiModel: ApiModel) {
        let baseSize = image.jpegData(compressionQuality: 1)!
        guard let data = baseSize.count < targetSize ? baseSize : self.jpegImage(image: image, maxSize: targetSize, minSize: targetSize * 9 / 10, times: 10) else {
            self.imageState = .failure(.tooLarge, image)
            return
        }
        let image = UIImage(data: data)!
        self.imageState = .uploading(0, image)
        apiModel.lemmyHttp!.uploadPhoto(data: data, mimeType: "image/jpeg") { percentDone in
            DispatchQueue.main.async {
                self.imageState = .uploading(percentDone, image)
            }
        } doneCallback: { url, error in
            DispatchQueue.main.async {
                if let url = url {
                    self.imageState = .success(url.files[0], image)
                } else if case .network(let code, _) = error {
                    if code == 413 {
                        self.imageState = .failure(.tooLarge, image)
                    } else {
                        self.imageState = .failure(.unknown, nil)
                    }
                }
            }
        }
    }
    
    func jpegImage(image: UIImage, maxSize: Int, minSize: Int, times: Int) -> Data? {
        var maxQuality: CGFloat = 1.0
        var minQuality: CGFloat = 0.0
        var bestData: Data?
        for _ in 1 ... times {
            let thisQuality = (maxQuality + minQuality) / 2
            guard let data = resizeWithPercent(image, percentage: thisQuality)!.jpegData(compressionQuality: thisQuality) else { return nil }
            let thisSize = data.count
            print(thisSize, thisQuality)
            if thisSize > maxSize {
                maxQuality = thisQuality
            } else {
                minQuality = thisQuality
                bestData = data
                if thisSize > minSize {
                    return bestData
                }
            }
        }

        return bestData
    }
    
    func resizeWithPercent(_ image: UIImage, percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: image.size.width * percentage, height: image.size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    struct ProfileImage: Transferable {
        let image: UIImage
        let data: Data
        
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return ProfileImage(image: uiImage, data: data)
            }
        }
    }
    
    enum ImageError: String {
        case loadingImage = "Error while loading image", tooLarge = "Image too large, tap to downsize", resize = "Resizing failed, size too small? Tap to retry", unknown = "Unkown image error"
    }
    
    enum ImageState: Equatable {
        var isError: Bool {
            if case .failure = self {
                return true
            }
            return false
        }

        case empty, loading(_ progress: Progress), uploading(_ percentDone: Double, _ image: UIImage), success(_ url: LemmyHttp.File, _ image: UIImage), failure(_ error: ImageError, _ image: UIImage?)
    }
    
    enum TransferError: Error {
        case importFailed
    }
}
