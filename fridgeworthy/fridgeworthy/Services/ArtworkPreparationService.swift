import CoreImage
import UIKit
import Vision

/// Corners use normalized image coordinates with the origin at the top left.
struct PaperCorners: Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    static let inset = PaperCorners(
        topLeft: CGPoint(x: 0.05, y: 0.05),
        topRight: CGPoint(x: 0.95, y: 0.05),
        bottomRight: CGPoint(x: 0.95, y: 0.95),
        bottomLeft: CGPoint(x: 0.05, y: 0.95)
    )

    var points: [CGPoint] { [topLeft, topRight, bottomRight, bottomLeft] }

    func replacing(_ index: Int, with point: CGPoint) -> PaperCorners {
        var copy = self
        let clamped = CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
        switch index {
        case 0: copy.topLeft = clamped
        case 1: copy.topRight = clamped
        case 2: copy.bottomRight = clamped
        default: copy.bottomLeft = clamped
        }
        return copy
    }

    var area: CGFloat {
        let vertices = points
        let sum = (0..<4).reduce(CGFloat.zero) { value, index in
            let next = (index + 1) % 4
            return value + vertices[index].x * vertices[next].y - vertices[next].x * vertices[index].y
        }
        return abs(sum) / 2
    }

    var isValid: Bool {
        guard area >= 0.04 else { return false }
        let vertices = points
        let turns = (0..<4).map { index -> CGFloat in
            let a = vertices[index]
            let b = vertices[(index + 1) % 4]
            let c = vertices[(index + 2) % 4]
            return (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
        }
        return turns.allSatisfy { $0 > 0.001 } || turns.allSatisfy { $0 < -0.001 }
    }
}

struct PaperDetection {
    let corners: PaperCorners
    let isConfident: Bool
}

/// Crops the paper without masks, contrast enhancement, or color changes.
final class ArtworkPreparationService {
    enum PreparationError: Error { case invalidImage, correctionFailed }

    private let context = CIContext()

    func orientedForProcessing(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        guard let cgImage = image.cgImage else { return image }
        let rotated: Bool
        switch image.imageOrientation {
        case .left, .right, .leftMirrored, .rightMirrored: rotated = true
        default: rotated = false
        }
        let size = rotated
            ? CGSize(width: cgImage.height, height: cgImage.width)
            : CGSize(width: cgImage.width, height: cgImage.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }

    func detect(in image: UIImage) throws -> PaperDetection? {
        guard let cgImage = image.cgImage else { throw PreparationError.invalidImage }
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 8
        request.minimumSize = 0.18
        request.minimumConfidence = 0.35
        request.minimumAspectRatio = 0.30
        request.maximumAspectRatio = 1
        request.quadratureTolerance = 35
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])

        let candidates = (request.results ?? []).map { observation -> (PaperCorners, Float) in
            func topOrigin(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x, y: 1 - point.y) }
            return (
                PaperCorners(
                    topLeft: topOrigin(observation.topLeft),
                    topRight: topOrigin(observation.topRight),
                    bottomRight: topOrigin(observation.bottomRight),
                    bottomLeft: topOrigin(observation.bottomLeft)
                ),
                observation.confidence
            )
        }
        let ranked = candidates.sorted { $0.0.area * CGFloat($0.1) > $1.0.area * CGFloat($1.1) }
        guard let best = ranked.first else {
            return nil
        }
        let corners = best.0
        let competingRectangle = ranked.dropFirst().first.map { $0.0.area >= corners.area * 0.8 } ?? false
        return PaperDetection(
            corners: corners,
            isConfident: corners.isValid && corners.area >= 0.38 && best.1 >= 0.65 && !competingRectangle
        )
    }

    func prepare(_ image: UIImage, corners: PaperCorners) throws -> UIImage {
        guard let cgImage = image.cgImage, corners.isValid else {
            throw PreparationError.invalidImage
        }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw PreparationError.correctionFailed
        }
        filter.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        func ciPoint(_ point: CGPoint) -> CIVector {
            CIVector(x: point.x * width, y: (1 - point.y) * height)
        }
        filter.setValue(ciPoint(corners.topLeft), forKey: "inputTopLeft")
        filter.setValue(ciPoint(corners.topRight), forKey: "inputTopRight")
        filter.setValue(ciPoint(corners.bottomRight), forKey: "inputBottomRight")
        filter.setValue(ciPoint(corners.bottomLeft), forKey: "inputBottomLeft")
        guard let output = filter.outputImage,
              let corrected = context.createCGImage(output, from: output.extent) else {
            throw PreparationError.correctionFailed
        }
        return UIImage(cgImage: corrected, scale: image.scale, orientation: .up)
    }
}
