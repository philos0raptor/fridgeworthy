import SwiftUI

struct FWMemoryMarker: View {
    let colors: [Color]

    private let compactOffsets: [CGSize] = [
        .init(width: 0, height: 0),
        .init(width: 7, height: -5),
        .init(width: -6, height: 5),
        .init(width: 4, height: 7),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                ZStack {
                    Circle()
                        .fill(color.opacity(0.42))

                    Image("FWStar")
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.4)
                        .clipped()
                }
                .frame(width: markerSize, height: markerSize)
                .clipShape(Circle())
                .offset(markerOffset(for: index))
                .zIndex(Double(index))
            }
        }
        .frame(width: 42, height: 40)
        .accessibilityHidden(true)
    }

    private var markerSize: CGFloat {
        max(15, 27 - CGFloat(max(colors.count - 4, 0)) * 1.5)
    }

    private func markerOffset(for index: Int) -> CGSize {
        if colors.count <= compactOffsets.count {
            return compactOffsets[index]
        }

        guard index > 0 else { return .zero }
        let angle = Double(index) * 2.399963229728653
        let radius = min(12.0, 3.0 + sqrt(Double(index)) * 3.2)
        return CGSize(
            width: CGFloat(cos(angle) * radius),
            height: CGFloat(sin(angle) * radius)
        )
    }
}
