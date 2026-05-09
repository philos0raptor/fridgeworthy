import Foundation
import SwiftData
import UIKit

/// Seeds the app with sample artwork from images prefixed with "seed_" in the app bundle.
///
/// Usage: rename your test photos to start with "seed_" (e.g. seed_dragon.jpg, seed_flowers.png)
/// and place them in the SeedPhotos folder. They'll be copied to Documents and linked as Artwork.
/// Only runs once — delete the app from simulator to re-seed, or call `reset()`.
enum SeedDataService {
    private static let seededKey = "com.fridgeworthy.hasSeededData"
    private static let imageExtensions = ["jpg", "jpeg", "png", "heic"]

    static func seedIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        // Collect all seed images from the bundle (files prefixed with "seed_")
        var seedURLs: [URL] = []
        for ext in imageExtensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                seedURLs.append(contentsOf: urls.filter { $0.lastPathComponent.lowercased().hasPrefix("seed_") })
            }
        }

        // Also check for any images inside a SeedPhotos folder reference (if added that way)
        for ext in imageExtensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "SeedPhotos") {
                seedURLs.append(contentsOf: urls)
            }
        }

        seedURLs.sort { $0.lastPathComponent < $1.lastPathComponent }
        guard !seedURLs.isEmpty else { return }

        // Ensure a child exists to attach artwork to
        let childDescriptor = FetchDescriptor<Child>()
        let existingChildren = (try? modelContext.fetch(childDescriptor)) ?? []
        let child: Child
        if let first = existingChildren.first {
            child = first
        } else {
            child = Child(name: "Sample Kid", avatarEmoji: "🎨")
            modelContext.insert(child)
        }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let artworkDir = documentsURL.appendingPathComponent("artworks")
        try? fileManager.createDirectory(at: artworkDir, withIntermediateDirectories: true)

        for (index, fileURL) in seedURLs.enumerated() {
            let filename = fileURL.lastPathComponent
            let destPath = "artworks/\(filename)"
            let destURL = documentsURL.appendingPathComponent(destPath)

            // Copy image to Documents
            if !fileManager.fileExists(atPath: destURL.path) {
                try? fileManager.copyItem(at: fileURL, to: destURL)
            }

            // Create Artwork record
            let artwork = Artwork(
                title: seedTitle(for: filename, index: index),
                artworkDescription: "Sample artwork for testing",
                localImagePath: destPath,
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 86400))
            )
            artwork.child = child
            modelContext.insert(artwork)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Reset seeding so it runs again next launch.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: seededKey)
    }

    private static func seedTitle(for filename: String, index: Int) -> String {
        var name = (filename as NSString).deletingPathExtension
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        // Strip "seed " prefix if present
        if name.lowercased().hasPrefix("seed ") {
            name = String(name.dropFirst(5))
        }

        // If filename is just numbers or generic, use a default
        if name.trimmingCharacters(in: .whitespaces).isEmpty ||
            name.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
            let titles = ["Rainbow Dragon", "Family Portrait", "Sunny Day", "Space Adventure",
                          "Flower Garden", "My Pet Cat", "Underwater World", "Castle in the Sky"]
            return titles[index % titles.count]
        }
        return name.trimmingCharacters(in: .whitespaces).capitalized
    }
}
