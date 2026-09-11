import Foundation
import Supabase

/// Central Supabase client wrapper. All network calls to Supabase go through this service.
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: AppConfig.supabaseURL, supabaseKey: AppConfig.supabaseAnonKey)
    }

    // MARK: - Style Templates

    func fetchStyleTemplates() async throws -> [StyleTemplateDTO] {
        try await client.from("style_templates")
            .select()
            .order("sort_order")
            .execute()
            .value
    }

    // MARK: - Profiles

    func upsertProfile(id: UUID, email: String?, displayName: String?) async throws {
        try await client.from("profiles")
            .upsert([
                "id": id.uuidString,
                "email": email ?? "",
                "display_name": displayName ?? "",
            ])
            .execute()
    }

    // MARK: - Children

    func fetchChildren() async throws -> [ChildDTO] {
        try await client.from("children")
            .select()
            .order("created_at")
            .execute()
            .value
    }

    func insertChild(id: UUID, name: String, profileID: UUID) async throws -> ChildDTO {
        try await client.from("children")
            .insert([
                "id": id.uuidString,
                "name": name,
                "profile_id": profileID.uuidString,
            ])
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Artworks

    /// How long a minted artwork URL stays valid. Long enough to outlive any screen
    /// that renders it, short enough that a leaked URL stops working the same day.
    private static let artworkURLLifetime = 60 * 60 * 8

    /// Uploads artwork and returns its **storage path** — not a URL.
    ///
    /// The path is `{profileID}/{childID}/{uuid}.png`. That leading profile segment is
    /// what the storage policy checks (see `002_scope_artwork_storage.sql`), so uploading
    /// outside your own prefix is rejected by Postgres rather than trusted from the client.
    func uploadArtwork(imageData: Data, childID: UUID) async throws -> String {
        let profileID = try await client.auth.session.user.id
        let path = "\(profileID.uuidString)/\(childID.uuidString)/\(UUID().uuidString).png"

        try await client.storage.from("artworks")
            .upload(path, data: imageData, options: .init(contentType: "image/png"))

        return path
    }

    /// Mints a short-lived signed URL for a stored artwork path.
    ///
    /// The bucket is private, so this is the only way to render one. Signed URLs expire,
    /// which is why the path — not the URL — is what gets persisted.
    func signedArtworkURL(path: String) async throws -> String {
        let url = try await client.storage.from("artworks")
            .createSignedURL(path: path, expiresIn: Self.artworkURLLifetime)
        return url.absoluteString
    }

    func insertArtwork(id: UUID, childID: UUID, storagePath: String) async throws -> ArtworkDTO {
        try await client.from("artworks")
            .insert([
                "id": id.uuidString,
                "child_id": childID.uuidString,
                "image_url": storagePath,
            ])
            .select()
            .single()
            .execute()
            .value
    }

    func fetchArtworks(childID: UUID) async throws -> [ArtworkDTO] {
        try await client.from("artworks")
            .select()
            .eq("child_id", value: childID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func deleteArtwork(id: UUID) async throws {
        try await client.from("artworks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func describeArtwork(artworkID: UUID) async throws -> String {
        let response: DescribeArtworkResponse = try await client.functions.invoke(
            "describe-artwork",
            options: .init(body: ["artwork_id": artworkID.uuidString])
        )
        return response.description
    }

    // MARK: - Wallpaper Generation

    func generateWallpaper(childID: UUID, styleTemplateID: UUID) async throws -> UUID {
        let response: GenerateWallpaperResponse = try await client.functions.invoke(
            "generate-wallpaper",
            options: .init(body: [
                "child_id": childID.uuidString,
                "style_template_id": styleTemplateID.uuidString,
            ])
        )
        return response.wallpaperID
    }

    func pollWallpaperStatus(jobID: UUID) async throws -> WallpaperStatusDTO {
        try await client.from("wallpapers")
            .select()
            .eq("id", value: jobID.uuidString)
            .single()
            .execute()
            .value
    }
}

// MARK: - DTOs

struct StyleTemplateDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String
    let previewImageURL: String?
    let promptTemplate: String
    let negativePrompt: String
    let tier: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case previewImageURL = "preview_image_url"
        case promptTemplate = "prompt_template"
        case negativePrompt = "negative_prompt"
        case tier
        case sortOrder = "sort_order"
    }
}

struct ChildDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let profileID: UUID
    let name: String
    let avatarEmoji: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case profileID = "profile_id"
        case avatarEmoji = "avatar_emoji"
        case createdAt = "created_at"
    }
}

struct ArtworkDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let childID: UUID
    /// Storage object path, not a URL — `image_url` keeps its column name for
    /// compatibility, but holds a path. Sign it with `signedArtworkURL(path:)` to render.
    let storagePath: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, description
        case childID = "child_id"
        case storagePath = "image_url"
    }
}

struct WallpaperStatusDTO: Codable, Sendable {
    let id: UUID
    let status: String
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case imageURL = "image_url"
    }
}

struct DescribeArtworkResponse: Codable, Sendable {
    let artworkID: UUID
    let description: String

    enum CodingKeys: String, CodingKey {
        case artworkID = "artwork_id"
        case description
    }
}

struct GenerateWallpaperResponse: Codable, Sendable {
    let wallpaperID: UUID
    let status: String
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case wallpaperID = "wallpaper_id"
        case status
        case imageURL = "image_url"
    }
}
