import Foundation
import SwiftData

@MainActor
@Observable
final class GalleryViewModel {
    var artworks: [Artwork] = []
    var isLoading = false
    var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    func loadArtworks(for child: Child) {
        artworks = child.artworks.sorted { $0.createdAt > $1.createdAt }
    }

    func syncWithRemote(child: Child, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let remoteArtworks = try await supabaseService.fetchArtworks(childID: child.id)
            let localIDs = Set(child.artworks.map(\.id))

            for dto in remoteArtworks {
                // The bucket is private, so a stored path renders only once signed.
                // A failure here must not drop the artwork — the record is still valid,
                // it just has no displayable URL this pass.
                let signedURL = try? await supabaseService.signedArtworkURL(path: dto.storagePath)

                if localIDs.contains(dto.id) {
                    // Update existing local record with remote data
                    if let local = child.artworks.first(where: { $0.id == dto.id }) {
                        local.storagePath = dto.storagePath
                        if let signedURL { local.remoteImageURL = signedURL }
                        if let desc = dto.description {
                            local.artworkDescription = desc
                        }
                    }
                } else {
                    // Artwork exists remotely but not locally (e.g. from another device)
                    let artwork = Artwork(
                        id: dto.id,
                        localImagePath: "",
                        storagePath: dto.storagePath,
                        remoteImageURL: signedURL,
                        backgroundRemoved: true
                    )
                    artwork.artworkDescription = dto.description
                    artwork.child = child
                    context.insert(artwork)
                }
            }

            loadArtworks(for: child)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteArtwork(_ artwork: Artwork, context: ModelContext) async {
        // Remove from remote
        do {
            try await supabaseService.deleteArtwork(id: artwork.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // Remove locally
        context.delete(artwork)
        artworks.removeAll { $0.id == artwork.id }
    }
}
