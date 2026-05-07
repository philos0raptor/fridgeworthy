import Foundation
import SwiftData

@Model
final class GenerationJob {
    @Attribute(.unique) var id: UUID
    var status: GenerationStatus
    var styleTemplateID: UUID
    var artworkIDs: [UUID]
    var errorMessage: String?
    var startedAt: Date
    var completedAt: Date?

    var wallpaper: Wallpaper?

    init(
        id: UUID = UUID(),
        status: GenerationStatus = .pending,
        styleTemplateID: UUID,
        artworkIDs: [UUID],
        errorMessage: String? = nil,
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.status = status
        self.styleTemplateID = styleTemplateID
        self.artworkIDs = artworkIDs
        self.errorMessage = errorMessage
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

enum GenerationStatus: String, Codable {
    case pending
    case processing
    case complete
    case failed
}
