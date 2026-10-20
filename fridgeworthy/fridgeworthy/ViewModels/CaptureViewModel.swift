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
    /// Set when the AI description call fails. Non-blocking: the artwork still saved.
    var descriptionError: String?

    private let backgroundRemovalService = BackgroundRemovalService()
    private let supabaseService = SupabaseService.shared

    /// Inserts a daily-memory photo locally before starting its remote upload.
    /// A failed upload never removes the keepsake from the family calendar.
    func saveMemoryImage(
        _ image: UIImage,
        note: String,
        date: Date,
        child: Child,
        context: ModelContext
    ) async -> Bool {
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

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let artwork = Artwork(
            title: trimmedNote.isEmpty ? nil : trimmedNote,
            localImagePath: filename,
            backgroundRemoved: false,
            createdAt: date
        )
        artwork.child = child
        context.insert(artwork)
        try? context.save()

        Task {
            do {
                let storagePath = try await supabaseService.uploadArtwork(
                    imageData: pngData,
                    childID: child.id
                )
                _ = try await supabaseService.insertArtwork(
                    id: artwork.id,
                    childID: child.id,
                    storagePath: storagePath,
                    title: artwork.title,
                    createdAt: date
                )
                artwork.storagePath = storagePath
                artwork.remoteImageURL = try await supabaseService.signedArtworkURL(path: storagePath)

                do {
                    artwork.artworkDescription = try await supabaseService.describeArtwork(artworkID: artwork.id)
                } catch {
                    descriptionError = error.localizedDescription
                }
            } catch {
                uploadError = error.localizedDescription
            }
        }

        return true
    }

    func updateMemoryNote(
        _ note: String,
        for artworks: [Artwork],
        context: ModelContext
    ) async {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let storedNote = trimmedNote.isEmpty ? nil : trimmedNote

        for artwork in artworks {
            artwork.title = storedNote
        }
        try? context.save()

        for artwork in artworks where artwork.storagePath != nil {
            do {
                try await supabaseService.updateArtworkTitle(id: artwork.id, title: storedNote)
            } catch {
                uploadError = error.localizedDescription
            }
        }
    }

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
            let storagePath = try await supabaseService.uploadArtwork(imageData: pngData, childID: child.id)
            _ = try await supabaseService.insertArtwork(
                id: artwork.id,
                childID: child.id,
                storagePath: storagePath,
                title: artwork.title,
                createdAt: artwork.createdAt
            )

            artwork.storagePath = storagePath
            artwork.remoteImageURL = try await supabaseService.signedArtworkURL(path: storagePath)

            // Fire AI description in background (non-blocking)
            let artworkID = artwork.id
            Task.detached { @MainActor in
                do {
                    artwork.artworkDescription = try await self.supabaseService.describeArtwork(artworkID: artworkID)
                } catch {
                    // Not fatal — the artwork is saved either way. But a swallowed failure
                    // here leaves `description` null, and generate-wallpaper then falls back
                    // to "colorful children's drawing" for every prompt, which looks like
                    // mediocre output rather than a broken call.
                    self.descriptionError = error.localizedDescription
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
