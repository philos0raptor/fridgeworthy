import Foundation
import SwiftData

@Model
final class Artwork {
    @Attribute(.unique) var id: UUID
    var title: String?
    var artworkDescription: String?
    var localImagePath: String
    /// Durable storage object path in the `artworks` bucket. Persist this, not the URL.
    var storagePath: String?
    /// Signed URL minted from `storagePath`. Expires — treat as a render-time cache,
    /// never as the source of truth.
    var remoteImageURL: String?
    var colorPalette: [String]
    var backgroundRemoved: Bool
    var createdAt: Date

    var child: Child?

    init(
        id: UUID = UUID(),
        title: String? = nil,
        artworkDescription: String? = nil,
        localImagePath: String,
        storagePath: String? = nil,
        remoteImageURL: String? = nil,
        colorPalette: [String] = [],
        backgroundRemoved: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artworkDescription = artworkDescription
        self.localImagePath = localImagePath
        self.storagePath = storagePath
        self.remoteImageURL = remoteImageURL
        self.colorPalette = colorPalette
        self.backgroundRemoved = backgroundRemoved
        self.createdAt = createdAt
    }
}
