import AppKit
import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
enum SignatureAssetTests {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let assetURL = root
            .appendingPathComponent("fridgeworthy/fridgeworthy/Assets.xcassets")
            .appendingPathComponent("FWPhil.imageset/phil.png")

        let imageData = try Data(contentsOf: assetURL)
        guard let bitmap = NSBitmapImageRep(data: imageData) else {
            fputs("FAIL: Phil signature must be a readable PNG\n", stderr)
            exit(1)
        }

        var firstInkRow = bitmap.pixelsHigh
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                if (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.02 {
                    firstInkRow = min(firstInkRow, y)
                }
            }
        }

        expect(firstInkRow >= 24, "Phil signature needs transparent headroom so the capital P is not clipped")
        print("signature asset tests passed")
    }
}
