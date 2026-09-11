import Foundation
import SwiftData

@MainActor
@Observable
final class WallpaperGenerationViewModel {
    var selectedStyle: StyleTemplate?
    var generationStatus: GenerationStatus = .pending
    var generatedWallpaperURL: String?
    var isGenerating = false
    var errorMessage: String?

    private let supabaseService = SupabaseService.shared
    private var pollingTask: Task<Void, Never>?

    func generate(for child: Child, style: StyleTemplate, context: ModelContext) {
        isGenerating = true
        generationStatus = .processing
        errorMessage = nil

        pollingTask = Task {
            do {
                let jobID = try await supabaseService.generateWallpaper(
                    childID: child.id,
                    styleSlug: style.slug
                )

                let job = GenerationJob(
                    styleTemplateID: style.id,
                    artworkIDs: child.artworks.map(\.id)
                )
                job.status = .processing
                context.insert(job)

                await pollForCompletion(jobID: jobID, job: job, child: child, style: style, context: context)
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    generationStatus = .failed
                    isGenerating = false
                }
            }
        }
    }

    private func pollForCompletion(jobID: UUID, job: GenerationJob, child: Child, style: StyleTemplate, context: ModelContext) async {
        let maxAttempts = 60
        for _ in 0..<maxAttempts {
            guard !Task.isCancelled else {
                generationStatus = .pending
                isGenerating = false
                return
            }

            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                generationStatus = .pending
                isGenerating = false
                return
            }

            do {
                let status = try await supabaseService.pollWallpaperStatus(jobID: jobID)

                if status.status == "complete" {
                    generatedWallpaperURL = status.imageURL
                    generationStatus = .complete
                    job.status = .complete
                    job.completedAt = Date()

                    let wallpaper = Wallpaper(
                        remoteImageURL: status.imageURL,
                        styleTemplateName: style.name
                    )
                    wallpaper.child = child
                    wallpaper.generationJob = job
                    context.insert(wallpaper)

                    isGenerating = false
                    return
                } else if status.status == "failed" {
                    generationStatus = .failed
                    job.status = .failed
                    errorMessage = "Wallpaper generation failed. Please try again."
                    isGenerating = false
                    return
                }
            } catch {
                // Continue polling on transient errors
            }
        }

        // Timeout
        if !Task.isCancelled {
            errorMessage = "Generation timed out. Please try again."
            generationStatus = .failed
            isGenerating = false
        }
    }

    func cancel() {
        pollingTask?.cancel()
        pollingTask = nil
        isGenerating = false
        generationStatus = .pending
    }
}
