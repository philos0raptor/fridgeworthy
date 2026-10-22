import SwiftUI

struct FWEntryDots: View {
    let colors: [Color]

    private let maxWidth: CGFloat = 40
    private let spacing: CGFloat = 1.5

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .frame(width: maxWidth, height: 5)
        .accessibilityHidden(true)
    }

    private var dotSize: CGFloat {
        guard !colors.isEmpty else { return 0 }
        let availableWidth = maxWidth - spacing * CGFloat(colors.count - 1)
        return min(4, max(2, availableWidth / CGFloat(colors.count)))
    }
}
