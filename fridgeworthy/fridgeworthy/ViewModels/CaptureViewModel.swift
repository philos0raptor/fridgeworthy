import UIKit
import SwiftData

@MainActor
@Observable
final class CaptureViewModel {
    var selectedImage: UIImage?
    var processedImage: UIImage?
    var isProcessing = false
    var isUploading = false
    var showBeforeAfter = false
    var errorMessage: String?
    var uploadError: String?

    private let backgroundRemovalService = BackgroundRemovalService()
    private let supabaseService = SupabaseService.shared

    func processImage(_ image: UIImage) async {
        selectedImage = image
        isProcessing = true
        errorMessage = nil

        do {
            processedImage = try await backgroundRemovalService.removeBackground(from: image)
            showBeforeAfter = true
        } catch {
            errorMessage = error.localizedDescription
            processedImage = image
            showBeforeAfter = true
        }

        isProcessing = false
    }

    /// Saves artwork locally and uploads to Supabase. Awaits upload completion.
    /// Returns true on success so the caller can navigate away.
    func saveArtwork(for child: Child, context: ModelContext) async -> Bool {
        guard let image = processedImage ?? selectedImage else { return false }

        // Save locally
        let filename = "\(UUID().uuidString).png"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)

        guard let pngData = image.pngData() else { return false }

        do {
            try pngData.write(to: fileURL)
        } catch {
            uploadError = "Failed to save image locally"
            return false
        }

        let artwork = Artwork(
            localImagePath: filename,
            backgroundRemoved: processedImage != nil
        )
        artwork.child = child
        context.insert(artwork)

        // Upload to Supabase
        isUploading = true
        uploadError = nil

        do {
            let remoteURL = try await supabaseService.uploadArtwork(imageData: pngData, childID: child.id)
            _ = try await supabaseService.insertArtwork(id: artwork.id, childID: child.id, imageURL: remoteURL)
            artwork.remoteImageURL = remoteURL

            // Fire AI description in background (non-blocking)
            let artworkID = artwork.id
            Task.detached { @MainActor in
                if let description = try? await self.supabaseService.describeArtwork(artworkID: artworkID) {
                    artwork.artworkDescription = description
                }
            }

            isUploading = false
            return true
        } catch {
            uploadError = error.localizedDescription
            isUploading = false
            return false
        }
    }

    func reset() {
        selectedImage = nil
        processedImage = nil
        showBeforeAfter = false
        errorMessage = nil
        uploadError = nil
        isUploading = false
    }
}
