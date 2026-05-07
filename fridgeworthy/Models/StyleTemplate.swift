import Foundation
import SwiftData

@Model
final class StyleTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var styleDescription: String
    var previewImageURL: String?
    var promptTemplate: String
    var negativePrompt: String
    var tier: SubscriptionTier
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        styleDescription: String,
        previewImageURL: String? = nil,
        promptTemplate: String,
        negativePrompt: String = "blurry, low quality, text, watermark, logo, cropped, deformed, photorealistic children, realistic child faces",
        tier: SubscriptionTier = .free,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.styleDescription = styleDescription
        self.previewImageURL = previewImageURL
        self.promptTemplate = promptTemplate
        self.negativePrompt = negativePrompt
        self.tier = tier
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
