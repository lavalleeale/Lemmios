import SwiftUI
import LemmyApi
import MarkdownUI

let gradient = LinearGradient(gradient: Gradient(colors: [Color(red: 0.74, green: 0.5, blue: 0.97), Color(red: 0.4, green: 0.86, blue: 0.91)]), startPoint: .topLeading, endPoint: .bottomTrailing)

struct PostComponent: View {
    @Environment(\.widgetFamily) var widgetFamily
    
    let post: LemmyApi.ApiPost
    let image: UIImage?
    
    var body: some View {
        let url = post.post.ap_id
        Link(destination: URL(string: url.absoluteString.replacingOccurrences(of: "$https", with: "lemmiosapp", options: .regularExpression))!) {
            ZStack(alignment: .topLeading) {
                if widgetFamily != .accessoryRectangular {
                    if let image = image {
                        Image(uiImage: image.resized(toWidth: 800)!)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        gradient
                    }
                }
                Group {
                        VStack(alignment: .leading, spacing: widgetFamily != .accessoryRectangular ? nil : 0) {
                            Text(post.post.name)
                            Text(post.community.name)
                                .font(.caption2)
                            Text(post.creator.name)
                                .font(.caption2)
                            if widgetFamily != .accessoryRectangular {
                                if image == nil, let body = post.post.body {
                                    Text(body)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            HStack {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up")
                                        .scaleEffect(0.8)
                                    Text(formatNum(num: post.counts.score))
                                    HStack(spacing: 3) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .scaleEffect(0.8)
                                        Text(formatNum(num: post.counts.comments))
                                    }
                                }
                            }
                        }
                        .padding()
                }
            }
        }.if(getTargetNum(widgetFamily) == 0) { view in
            view.widgetURL(URL(string: url.absoluteString.replacingOccurrences(of: "$https", with: "lemmiosapp", options: .regularExpression))!)
        }
    }
}

extension UIImage {
  func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
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
