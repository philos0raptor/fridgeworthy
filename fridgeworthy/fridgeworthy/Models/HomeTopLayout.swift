import CoreGraphics

enum HomeTopLayout {
    static func monthTop(safeAreaTop: CGFloat, gap: CGFloat = 4) -> CGFloat {
        max(0, safeAreaTop) + gap
    }
}
