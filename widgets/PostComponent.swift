import SwiftUI
import LemmyApi

struct PostComponent: View {
    @Environment(\.widgetFamily) var widgetFamily
    
    let info: WidgetInfo
    
    var body: some View {
        Link(destination: info.postUrl) {
            ZStack(alignment: .topLeading) {
                if widgetFamily != .accessoryRectangular {
                    if let image = info.image {
                        Image(uiImage: image.resized(toWidth: 256))
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        LinearGradient(gradient: Gradient(colors: [Color(red: 0.74, green: 0.5, blue: 0.97), Color(red: 0.4, green: 0.86, blue: 0.91)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                Group {
                        VStack(alignment: .leading, spacing: widgetFamily != .accessoryRectangular ? nil : 0) {
                            Text(info.postName)
                            Text(info.postCommunity)
                                .font(.caption2)
                            if widgetFamily != .accessoryRectangular {
                                Text(info.postCreator)
                                    .font(.caption2)
                                if info.image == nil, let body = info.postBody {
                                    Text(body)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            HStack {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up")
                                        .scaleEffect(0.8)
                                    Text(formatNum(num: info.score))
                                    HStack(spacing: 3) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .scaleEffect(0.8)
                                        Text(formatNum(num: info.numComments))
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
  func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage {
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
}
