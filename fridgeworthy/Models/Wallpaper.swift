import Foundation
import SwiftData

@Model
final class Wallpaper {
    @Attribute(.unique) var id: UUID
    var localImagePath: String?
    var remoteImageURL: String?
    var styleTemplateName: String
    var aspectRatio: String
    var resolution: String
    var isWatermarked: Bool
    var createdAt: Date

    var child: Child?

    @Relationship(inverse: \GenerationJob.wallpaper)
    var generationJob: GenerationJob?

    init(
        id: UUID = UUID(),
        localImagePath: String? = nil,
        remoteImageURL: String? = nil,
        styleTemplateName: String,
        aspectRatio: String = "9:19.5",
        resolution: String = "1170x2532",
        isWatermarked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.localImagePath = localImagePath
        self.remoteImageURL = remoteImageURL
        self.styleTemplateName = styleTemplateName
        self.aspectRatio = aspectRatio
        self.resolution = resolution
        self.isWatermarked = isWatermarked
        self.createdAt = createdAt
    }
}
