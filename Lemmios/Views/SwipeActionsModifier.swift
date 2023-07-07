import Foundation
import SimpleHaptics
import SwiftUI

struct SwipeOption: Hashable {
    var id: String
    var image: String
    var color: Color
}

struct SwiperContainer: ViewModifier {
    @State private var offset: CGFloat = 0
    @EnvironmentObject var haptics: SimpleHapticGenerator
    let minTrailingOffset: CGFloat
    let leadingOptions: [SwipeOption]
    let trailingOptions: [SwipeOption]
    let action: (String) -> Void

    init(leadingOptions: [SwipeOption], trailingOptions: [SwipeOption], action: @escaping (String) -> Void) {
        self.leadingOptions = leadingOptions
        self.trailingOptions = trailingOptions
        self.minTrailingOffset = CGFloat(trailingOptions.count) * -125
        self.action = action
    }

    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(leadingOptions.enumerated().reversed()), id: \.element) { index, option in
                let showing = calcLeadingShowing(index: index, offset: offset)
                ZStack {
                    Rectangle()
                        .foregroundColor(option.color)
                    Image(systemName: option.image)
                        .resizable()
                        .background(.clear)
                        .foregroundStyle(.white)
                        .frame(width: offset > 50 && showing ? 20 : 0, height: offset > 50 && showing ? 20 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.5, blendDuration: 0), value: offset)
                }
                .onChange(of: offset) { [offset] newOffset in
                    if (!calcLeadingShowing(index: index, offset: offset) || offset <= 50) && (calcLeadingShowing(index: index, offset: newOffset) && newOffset > 50) {
                        try? haptics.fire(intensity: 1, sharpness: 1)
                    }
                }
                .frame(maxWidth: showing ? offset : 0)
            }
            content
            ForEach(Array(trailingOptions.enumerated()), id: \.element) { index, option in
                let showing = calcTrailingShowing(index: index, offset: offset)
                ZStack {
                    Rectangle()
                        .foregroundColor(option.color)
                    Image(systemName: option.image)
                        .resizable()
                        .background(.clear)
                        .foregroundStyle(.white)
                        .frame(width: offset < -50 && showing ? 20 : 0, height: offset < -50 && showing ? 20 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.5, blendDuration: 0), value: offset)
                }
                .onChange(of: offset) { [offset] newOffset in
                    if (!calcTrailingShowing(index: index, offset: offset) || offset >= -50) && (calcTrailingShowing(index: index, offset: newOffset) && newOffset < -50) {
                        try? haptics.fire(intensity: 1, sharpness: 1)
                    }
                }
                .frame(maxWidth: showing ? -offset : 0)
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 25, coordinateSpace: .local)
            .onChanged { value in
                let totalSlide = value.translation.width
                withAnimation {
                    offset = totalSlide
                }
            }
            .onEnded { _ in
                let index = Int(floor(offset / CGFloat(125)))
                if offset > 50 {
                    action(leadingOptions[min(index, leadingOptions.count - 1)].id)
                } else if offset < -50 {
                    action(trailingOptions[min(-index - 1, trailingOptions.count - 1)].id)
                }
                withAnimation {
                    offset = 0
                }
            }
        )
    }

    private func calcLeadingShowing(index: Int, offset: CGFloat) -> Bool {
        return ((index == leadingOptions.count - 1 || offset <= CGFloat(index + 1) * 125) && (offset > CGFloat(index) * 125))
    }

    private func calcTrailingShowing(index: Int, offset: CGFloat) -> Bool {
        return ((index == trailingOptions.count - 1 || offset >= CGFloat(index + 1) * -125) && (offset < CGFloat(index) * -125))
    }
}
