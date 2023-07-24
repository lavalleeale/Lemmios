import SwiftUI
import LemmyApi

struct PostComponent: View {
    @Environment(\.widgetFamily) var widgetFamily
    
    let info: WidgetInfo
    
    var body: some View {
        let averageColor = info.image?.averageColor
        Link(destination: info.postUrl) {
            ZStack(alignment: .topLeading) {
                if widgetFamily != .accessoryRectangular {
                    LinearGradient(gradient: Gradient(colors: [Color(red: 0.74, green: 0.5, blue: 0.97), Color(red: 0.4, green: 0.86, blue: 0.91)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    if let image = info.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
                Group {
                        VStack(alignment: .leading, spacing: widgetFamily != .accessoryRectangular ? nil : 0) {
                            Text(info.postName)
                                .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                            Text(info.postCommunity)
                                .font(.caption2)
                                .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                            if widgetFamily != .accessoryRectangular {
                                Text(info.postCreator)
                                    .font(.caption2)
                                    .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                                if info.image == nil, let body = info.postBody {
                                    Text(body)
                                        .font(.caption)
                                        .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                                }
                                Spacer()
                            }
                            HStack {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up")
                                        .scaleEffect(0.8)
                                        .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                                    Text(formatNum(num: info.score))
                                        .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                                    HStack(spacing: 3) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .scaleEffect(0.8)
                                            .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                                        Text(formatNum(num: info.numComments))
                                            .getContrast(backgroundColor: averageColor != nil ? Color(averageColor!) : .black)
                                    }
                                }
                            }
                        }
                        .padding()
                }
            }
        }.if(getTargetNum(widgetFamily) == 0) { view in
            view.widgetURL(info.postUrl)
        }
    }
}

extension UIImage {
  func resized(toWidth width: CGFloat, isOpaque: Bool = false) -> UIImage {
    let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
    let format = imageRendererFormat
    format.opaque = isOpaque
    return UIGraphicsImageRenderer(size: canvas, format: format).image {
      _ in draw(in: CGRect(origin: .zero, size: canvas))
    }
  }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    func getContrast(backgroundColor: Color) -> some View {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(backgroundColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return  luminance < 0.6 ? self.foregroundColor(.white) : self.foregroundColor(.black)
    }
}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
