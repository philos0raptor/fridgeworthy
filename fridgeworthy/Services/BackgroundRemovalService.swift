import UIKit
import Vision
import CoreImage

/// Removes backgrounds from artwork photos using Apple Vision framework.
/// Strategy: try subject lifting first, fall back to saliency-based segmentation.
final class BackgroundRemovalService {

    enum RemovalError: LocalizedError {
        case imageConversionFailed
        case segmentationFailed
        case noSubjectFound

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed: return "Failed to process image"
            case .segmentationFailed: return "Background removal failed"
            case .noSubjectFound: return "No artwork subject detected"
            }
        }
    }

    /// Attempts to isolate the artwork subject from its background.
    /// Returns a PNG with transparent background.
    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw RemovalError.imageConversionFailed
        }

        // Try subject lifting (iOS 17+)
        if #available(iOS 17.0, *) {
            if let result = try? await subjectLifting(cgImage: cgImage) {
                return result
            }
        }

        // Fallback: saliency-based segmentation
        return try await saliencySegmentation(cgImage: cgImage)
    }

    // MARK: - Subject Lifting (iOS 17+)

    @available(iOS 17.0, *)
    private func subjectLifting(cgImage: CGImage) async throws -> UIImage {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw RemovalError.noSubjectFound
        }

        let maskPixelBuffer = try result.generateScaledMaskForImage(
            forInstances: result.allInstances,
            from: handler
        )

        let maskedImage = try applyMask(maskPixelBuffer, to: cgImage)
        return maskedImage
    }

    // MARK: - Saliency Fallback

    private func saliencySegmentation(cgImage: CGImage) async throws -> UIImage {
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw RemovalError.segmentationFailed
        }
        let salientPixelBuffer = result.pixelBuffer

        let maskedImage = try applyMask(salientPixelBuffer, to: cgImage)
        return maskedImage
    }

    // MARK: - Mask Application

    private func applyMask(_ maskBuffer: CVPixelBuffer, to cgImage: CGImage) throws -> UIImage {
        let ciImage = CIImage(cgImage: cgImage)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)

        let context = CIContext()
        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            throw RemovalError.segmentationFailed
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(maskImage.transformed(by: .init(
            scaleX: ciImage.extent.width / maskImage.extent.width,
            y: ciImage.extent.height / maskImage.extent.height
        )), forKey: kCIInputMaskImageKey)
        filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)

        guard let outputImage = filter.outputImage,
              let outputCGImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            throw RemovalError.segmentationFailed
        }

        return UIImage(cgImage: outputCGImage)
    }
}
