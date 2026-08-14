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
            // Silently fail — fall through to local seed if we have nothing cached
        }

        seedDefaultsIfEmpty(context: context)
    }

    /// Inserts the built-in style templates if the local store has none.
    /// Matches the six styles in supabase/migrations/001_initial_schema.sql so
    /// the picker is usable in dev without a live Supabase backend.
    private static func seedDefaultsIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<StyleTemplate>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for defaults in Self.defaults {
            context.insert(StyleTemplate(
                name: defaults.name,
                styleDescription: defaults.description,
                promptTemplate: defaults.promptTemplate,
                tier: defaults.tier,
                sortOrder: defaults.sortOrder
            ))
        }
        try? context.save()
    }

    private struct StyleDefaults {
        let name: String
        let description: String
        let promptTemplate: String
        let tier: SubscriptionTier
        let sortOrder: Int
    }

    private static let defaults: [StyleDefaults] = [
        StyleDefaults(
            name: "Watercolor Garden",
            description: "Soft watercolor storybook style with gentle color bleeds on cold-press paper",
            promptTemplate: "A seamless phone wallpaper in soft watercolor storybook style, cold-press paper texture, gentle color bleeds. Blend the children's artwork motifs — {artwork_description} — in a whimsical garden scene with flowers, leaves, and soft sunlight. Use colors from this palette: {color_palette}. Pastel palette, no harsh edges. {aspect_ratio} {resolution}",
            tier: .free,
            sortOrder: 1
        ),
        StyleDefaults(
            name: "Geometric Mosaic",
            description: "Clean flat geometric shapes with bold primary and secondary colors",
            promptTemplate: "A seamless phone wallpaper in geometric mosaic style, clean flat shapes, bold primary and secondary colors. Reinterpret the children's artwork — {artwork_description} — as abstracted geometric tiles arranged in a harmonious grid pattern. Crisp edges, solid fills, no gradients. {aspect_ratio} {resolution}",
            tier: .free,
            sortOrder: 2
        ),
        StyleDefaults(
            name: "Pencil Sketch",
            description: "Detailed graphite pencil drawings on warm cream paper with cross-hatching",
            promptTemplate: "A seamless phone wallpaper in detailed pencil sketch style on warm cream paper. Render the children's artwork subjects — {artwork_description} — as refined graphite pencil drawings with visible cross-hatching and soft shading. Scattered across the composition with generous white space. {aspect_ratio} {resolution}",
            tier: .free,
            sortOrder: 3
        ),
        StyleDefaults(
            name: "Storybook Adventure",
            description: "Gouache storybook illustration with matte opaque paint and warm cozy palette",
            promptTemplate: "A seamless phone wallpaper in gouache storybook illustration style, matte opaque paint, rounded friendly forms, warm cozy palette. Place the children's artwork characters — {artwork_description} — into an adventure scene as if illustrating a children's picture book. {child_name}'s magical world. {aspect_ratio} {resolution}",
            tier: .pro,
            sortOrder: 4
        ),
        StyleDefaults(
            name: "Cut-Paper Collage",
            description: "Layered paper textures with torn edges and drop shadows on kraft background",
            promptTemplate: "A seamless phone wallpaper in cut-paper collage style, layered paper textures with visible torn edges and subtle drop shadows. Reinterpret the children's artwork — {artwork_description} — as paper cutout elements layered over kraft paper background. Handmade, tactile aesthetic. {aspect_ratio} {resolution}",
            tier: .pro,
            sortOrder: 5
        ),
        StyleDefaults(
            name: "Pop Art Burst",
            description: "Bold pop art with halftone dots, thick outlines, and vibrant saturated colors",
            promptTemplate: "A seamless phone wallpaper in pop art style. Transform the children's artwork — {artwork_description} — into bold, high-contrast panels with halftone dots, thick black outlines, and vibrant saturated primary colors. Comic-book energy, repeated motifs in different color treatments. {aspect_ratio} {resolution}",
            tier: .pro,
            sortOrder: 6
        ),
    ]
}
