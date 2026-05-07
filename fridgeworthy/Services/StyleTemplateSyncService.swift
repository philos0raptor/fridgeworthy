import Foundation
import SwiftData

@MainActor
enum StyleTemplateSyncService {

    static func sync(context: ModelContext) async {
        do {
            let remoteDTOs = try await SupabaseService.shared.fetchStyleTemplates()

            for dto in remoteDTOs {
                let descriptor = FetchDescriptor<StyleTemplate>(
                    predicate: #Predicate { $0.id == dto.id }
                )

                if let existing = try context.fetch(descriptor).first {
                    existing.name = dto.name
                    existing.styleDescription = dto.description
                    existing.previewImageURL = dto.previewImageURL
                    existing.promptTemplate = dto.promptTemplate
                    existing.negativePrompt = dto.negativePrompt
                    existing.tier = SubscriptionTier(rawValue: dto.tier) ?? .free
                    existing.sortOrder = dto.sortOrder
                } else {
                    let template = StyleTemplate(
                        id: dto.id,
                        name: dto.name,
                        styleDescription: dto.description,
                        previewImageURL: dto.previewImageURL,
                        promptTemplate: dto.promptTemplate,
                        negativePrompt: dto.negativePrompt,
                        tier: SubscriptionTier(rawValue: dto.tier) ?? .free,
                        sortOrder: dto.sortOrder
                    )
                    context.insert(template)
                }
            }
        } catch {
            // Silently fail — use cached templates if available
        }
    }
}
