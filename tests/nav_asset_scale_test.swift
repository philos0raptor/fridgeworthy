import CoreGraphics
import Foundation
import ImageIO

private struct AlphaBounds {
    let canvasWidth: Int
    let canvasHeight: Int
    let contentWidth: Int
    let contentHeight: Int
}

private func alphaBounds(at path: String) throws -> AlphaBounds {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw NSError(domain: "NavAssetScaleTest", code: 1)
    }

    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "NavAssetScaleTest", code: 2)
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1
    for y in 0..<height {
        for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 8 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }

    guard maxX >= minX, maxY >= minY else {
        throw NSError(domain: "NavAssetScaleTest", code: 3)
    }
    return AlphaBounds(
        canvasWidth: width,
        canvasHeight: height,
        contentWidth: maxX - minX + 1,
        contentHeight: maxY - minY + 1
    )
}

@main
private enum NavAssetScaleTest {
    static func main() throws {
        let assets = [
            ("Add-memory", "fridgeworthy/fridgeworthy/Assets.xcassets/FWNavCapture.imageset/capture.png"),
            ("Camera action", "fridgeworthy/fridgeworthy/Assets.xcassets/FWActionCamera.imageset/camera.png"),
            ("Gallery action", "fridgeworthy/fridgeworthy/Assets.xcassets/FWActionGallery.imageset/gallery.png"),
        ]

        for (name, path) in assets {
            let bounds = try alphaBounds(at: path)
            let widthRatio = Double(bounds.contentWidth) / Double(bounds.canvasWidth)
            let heightRatio = Double(bounds.contentHeight) / Double(bounds.canvasHeight)

            precondition(
                widthRatio >= 0.40 && heightRatio >= 0.38,
                "\(name) artwork has excessive transparent padding (\(widthRatio) × \(heightRatio))"
            )
        }
        print("nav asset scale tests passed")
    }
}
