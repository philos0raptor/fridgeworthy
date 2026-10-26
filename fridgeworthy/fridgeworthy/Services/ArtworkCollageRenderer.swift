import UIKit

enum ArtworkCollageRenderer {
    static func render(images: [UIImage], title: String) -> UIImage? {
        let frames = ArtworkCollageLayout.frames(count: images.count)
        guard !frames.isEmpty else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: ArtworkCollageLayout.canvasSize, format: format)

        return renderer.image { context in
            let canvas = CGRect(origin: .zero, size: ArtworkCollageLayout.canvasSize)
            UIColor(red: 0.992, green: 0.976, blue: 0.95, alpha: 1).setFill()
            context.fill(canvas)

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let heading = NSAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 47, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.19, green: 0.17, blue: 0.21, alpha: 1),
                    .paragraphStyle: paragraph,
                ]
            )
            heading.draw(in: CGRect(x: 70, y: 356, width: 1030, height: 76))

            for (image, frame) in zip(images, frames) {
                let radius = min(CGFloat(28), frame.height / 5)
                let rounded = UIBezierPath(roundedRect: frame, cornerRadius: radius)
                UIColor.white.setFill()
                rounded.fill()

                let padding = min(CGFloat(18), frame.height / 10)
                let inset = frame.insetBy(dx: padding, dy: padding)
                let imageSize = image.size
                guard imageSize.width > 0, imageSize.height > 0 else { continue }
                let scale = min(inset.width / imageSize.width, inset.height / imageSize.height)
                let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                let drawFrame = CGRect(
                    x: inset.midX - drawSize.width / 2,
                    y: inset.midY - drawSize.height / 2,
                    width: drawSize.width,
                    height: drawSize.height
                )
                context.cgContext.saveGState()
                rounded.addClip()
                image.draw(in: drawFrame)
                context.cgContext.restoreGState()
            }
        }
    }
}
