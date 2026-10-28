import UIKit
import SwiftData

@MainActor
@Observable
final class CaptureViewModel {
    var selectedImage: UIImage?
    var processedImage: UIImage?
    var paperCorners: PaperCorners?
    var detectionUncertain = false
    var isAdjustingCorners = false
    var hasChosenPreparation = false
    var isProcessing = false
    var isUploading = false
    var showBeforeAfter = false
    var errorMessage: String?
    var uploadError: String?
    /// Set when the AI description call fails. Non-blocking: the artwork still saved.
    var descriptionError: String?

    private let preparationService = ArtworkPreparationService()
    private var processingImage: UIImage?
    var imageForCornerEditing: UIImage? { processingImage }
    private var originalImageData: Data?
    private var pendingArtwork: Artwork?
    private let supabaseService = SupabaseService.shared

    /// Inserts a daily-memory photo locally before starting its remote upload.
    /// A failed upload never removes the keepsake from the family calendar.
    func saveMemoryImage(
        _ photo: PendingArtworkPhoto,
        note: String,
        date: Date,
        child: Child,
        context: ModelContext
    ) async -> Bool {
        let filename = "\(UUID().uuidString)-prepared.png"
        let sourceType = Self.sourceFormat(for: photo.originalData)
        let originalFilename = "\(UUID().uuidString)-original.\(sourceType.extension)"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        let originalURL = documentsURL.appendingPathComponent(originalFilename)

        guard let pngData = photo.preparedImage.pngData() else { return false }

        do {
            try photo.originalData.write(to: originalURL, options: .atomic)
            try pngData.write(to: fileURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            uploadError = "Failed to save image locally"
            return false
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let artwork = Artwork(
            title: trimmedNote.isEmpty ? nil : trimmedNote,
            localImagePath: filename,
            originalLocalImagePath: originalFilename,
            backgroundRemoved: false,
            createdAt: date
        )
        artwork.child = child
        context.insert(artwork)
        try? context.save()

        Task {
            do {
                let originalStoragePath = try await supabaseService.uploadArtwork(
                    imageData: photo.originalData,
                    childID: child.id,
                    contentType: sourceType.mime,
                    fileExtension: sourceType.extension
                )
                artwork.originalStoragePath = originalStoragePath
                let storagePath = try await supabaseService.uploadArtwork(
                    imageData: pngData,
                    childID: child.id
                )
                _ = try await supabaseService.insertArtwork(
                    id: artwork.id,
                    childID: child.id,
                    storagePath: storagePath,
                    originalStoragePath: originalStoragePath,
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

    func processImage(_ image: UIImage, originalData: Data? = nil) async {
        selectedImage = image
        originalImageData = originalData ?? image.pngData()
        processingImage = preparationService.orientedForProcessing(image)
        processedImage = nil
        paperCorners = nil
        hasChosenPreparation = false
        detectionUncertain = false
        isAdjustingCorners = false
        isProcessing = true
        errorMessage = nil

        do {
            if let processingImage, let detection = try preparationService.detect(in: processingImage) {
                paperCorners = detection.corners
                detectionUncertain = !detection.isConfident
                if detection.isConfident {
                    processedImage = try preparationService.prepare(processingImage, corners: detection.corners)
                    hasChosenPreparation = true
                }
            } else {
                paperCorners = .inset
                detectionUncertain = true
            }
        } catch {
            paperCorners = .inset
            detectionUncertain = true
        }

        showBeforeAfter = true
        isProcessing = false
    }

    func prepareWithAdjustedCorners() {
        guard let processingImage, let paperCorners else { return }
        do {
            processedImage = try preparationService.prepare(processingImage, corners: paperCorners)
            hasChosenPreparation = true
            isAdjustingCorners = false
            errorMessage = nil
        } catch {
            errorMessage = "Please move the corners onto the paper before continuing."
        }
    }

    func keepOriginal() {
        processedImage = selectedImage
        hasChosenPreparation = true
        isAdjustingCorners = false
    }

    /// Saves artwork locally and uploads to Supabase. Awaits upload completion.
    /// Returns true on success so the caller can navigate away.
    func saveArtwork(for child: Child, context: ModelContext) async -> Bool {
        guard hasChosenPreparation, let image = processedImage,
              let originalData = originalImageData else { return false }

        // The source is written first; a prepared image can never be the only local copy.
        let sourceType = Self.sourceFormat(for: originalData)
        let originalFilename = pendingArtwork?.originalLocalImagePath ?? "\(UUID().uuidString)-original.\(sourceType.extension)"
        let filename = pendingArtwork?.localImagePath ?? "\(UUID().uuidString)-prepared.png"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        let originalURL = documentsURL.appendingPathComponent(originalFilename)

        guard let pngData = image.pngData() else { return false }

        do {
            try originalData.write(to: originalURL, options: .atomic)
            try pngData.write(to: fileURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            uploadError = "Failed to save image locally"
            return false
        }

        let artwork: Artwork
        if let pendingArtwork {
            artwork = pendingArtwork
            artwork.localImagePath = filename
            artwork.originalLocalImagePath = originalFilename
        } else {
            artwork = Artwork(
                localImagePath: filename,
                originalLocalImagePath: originalFilename,
                backgroundRemoved: false
            )
            artwork.child = child
            context.insert(artwork)
            pendingArtwork = artwork
        }
        try? context.save()

        // Upload to Supabase
        isUploading = true
        uploadError = nil

        do {
            let originalStoragePath: String
            if let existing = artwork.originalStoragePath {
                originalStoragePath = existing
            } else {
                originalStoragePath = try await supabaseService.uploadArtwork(
                    imageData: originalData,
                    childID: child.id,
                    contentType: sourceType.mime,
                    fileExtension: sourceType.extension
                )
                artwork.originalStoragePath = originalStoragePath
            }
            let storagePath: String
            if let existing = artwork.storagePath {
                storagePath = existing
            } else {
                storagePath = try await supabaseService.uploadArtwork(imageData: pngData, childID: child.id)
                artwork.storagePath = storagePath
            }
            _ = try await supabaseService.insertArtwork(
                id: artwork.id,
                childID: child.id,
                storagePath: storagePath,
                originalStoragePath: originalStoragePath,
                title: artwork.title,
                createdAt: artwork.createdAt
            )

            artwork.remoteImageURL = try? await supabaseService.signedArtworkURL(path: storagePath)
            try? context.save()
            pendingArtwork = nil

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
        processingImage = nil
        originalImageData = nil
        paperCorners = nil
        detectionUncertain = false
        isAdjustingCorners = false
        hasChosenPreparation = false
        pendingArtwork = nil
        showBeforeAfter = false
        errorMessage = nil
        uploadError = nil
        isUploading = false
    }

    private static func sourceFormat(for data: Data) -> (extension: String, mime: String) {
        let bytes = [UInt8](data.prefix(12))
        if bytes.starts(with: [0xFF, 0xD8]) { return ("jpg", "image/jpeg") }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return ("png", "image/png") }
        if bytes.count >= 12 && ["heic", "heix", "hevc", "hevx"].contains(where: {
            String(bytes: bytes[4..<12], encoding: .ascii)?.contains($0) == true
        }) {
            return ("heic", "image/heic")
        }
        return ("bin", "application/octet-stream")
    }
}
