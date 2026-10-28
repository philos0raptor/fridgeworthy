import Foundation
import CoreGraphics

enum ArtworkCollageLayout {
    static let canvasSize = CGSize(width: 1170, height: 2532)

    static func frames(count: Int) -> [CGRect] {
        guard count > 0 else { return [] }

        let left: CGFloat = 70
        let top: CGFloat = 450
        let bottom: CGFloat = 110
        let horizontalGap: CGFloat = 22
        let columns = count == 1 ? 1 : 2
        let rows = (count + columns - 1) / columns
        let usableWidth = canvasSize.width - left * 2
        let usableHeight = canvasSize.height - top - bottom
        let verticalGap = min(CGFloat(22), usableHeight / CGFloat(rows) / 4)
        let tileWidth = (usableWidth - horizontalGap * CGFloat(columns - 1)) / CGFloat(columns)
        let tileHeight = (usableHeight - verticalGap * CGFloat(rows - 1)) / CGFloat(rows)

        return (0..<count).map { index in
            let row = index / columns
            let column = index % columns
            let isLastOddTile = columns == 2 && count.isMultiple(of: 2) == false && index == count - 1
            let x: CGFloat = left + CGFloat(column) * (tileWidth + horizontalGap)
            let y: CGFloat = top + CGFloat(row) * (tileHeight + verticalGap)
            let width: CGFloat = isLastOddTile ? usableWidth : tileWidth
            return CGRect(
                x: x,
                y: y,
                width: width,
                height: tileHeight
            )
        }
    }
}
