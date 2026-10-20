import CoreGraphics

enum MonthGridLayout {
    static func rowSpacing(
        rowCount: Int,
        targetHeight: CGFloat,
        cellHeight: CGFloat,
        minimum: CGFloat = 18,
        maximum: CGFloat = 54
    ) -> CGFloat {
        guard rowCount > 1 else { return 0 }

        let occupiedHeight = CGFloat(rowCount) * cellHeight
        let availableSpacing = (targetHeight - occupiedHeight) / CGFloat(rowCount - 1)
        return min(max(availableSpacing, minimum), maximum)
    }
}
