import Foundation
import SwiftUI

func showShareSheet(url: URL) {
  let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
  UIApplication.shared.currentUIWindow()?.rootViewController?.present(activityVC, animated: true, completion: nil)
}

