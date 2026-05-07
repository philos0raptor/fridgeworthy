import SwiftUI
import SwiftData

struct WallpaperView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WallpaperGenerationViewModel()

    let child: Child
    let style: StyleTemplate

    var body: some View {
        VStack {
            switch viewModel.generationStatus {
            case .pending:
                readyToGenerate
            case .processing:
                generatingView
            case .complete:
                wallpaperPreview
            case .failed:
                failedView
            }
        }
        .background(FW.Color.bg)
        .navigationTitle("Wallpaper")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var readyToGenerate: some View {
        VStack(spacing: 24) {
            Spacer()

            // Device frame preview
            RoundedRectangle(cornerRadius: FW.Radius.deviceOuter, style: .continuous)
                .fill(Color.black)
                .frame(width: 200, height: 340)
                .overlay {
                    RoundedRectangle(cornerRadius: FW.Radius.deviceScreen, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [FW.Color.cream1, FW.Color.accent.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(4)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 32))
                                    .foregroundStyle(FW.Color.accent.opacity(0.5))
                                Text(style.name)
                                    .font(FW.Font.caption(13, weight: .medium))
                                    .foregroundStyle(FW.Color.ink3)
                            }
                        }
                }
                .modifier(FW.Shadow.cardHero())

            Text("Ready to create a \(style.name) wallpaper")
                .font(FW.Font.sectionTitle())
                .multilineTextAlignment(.center)

            Text("Using \(child.artworks.count) artwork\(child.artworks.count == 1 ? "" : "s") from \(child.name)")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)

            FWButton(title: "Generate Wallpaper", icon: "wand.and.stars") {
                Task {
                    await viewModel.generate(for: child, style: style, context: modelContext)
                }
            }
            .padding(.horizontal, FW.Spacing.xl)

            Spacer()
        }
        .padding(.horizontal, FW.Spacing.md)
    }

    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(2)
                .tint(FW.Color.accent)

            Text("Creating your wallpaper...")
                .font(FW.Font.sectionTitle())

            Text("This usually takes 15-30 seconds")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)

            Spacer()
        }
    }

    private var wallpaperPreview: some View {
        VStack(spacing: 20) {
            if let urlString = viewModel.generatedWallpaperURL,
               let url = URL(string: urlString) {
                // Device frame with wallpaper
                RoundedRectangle(cornerRadius: FW.Radius.deviceOuter, style: .continuous)
                    .fill(Color.black)
                    .frame(width: 240, height: 420)
                    .overlay {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: FW.Radius.deviceScreen, style: .continuous))
                        .padding(4)
                    }
                    .modifier(FW.Shadow.cardHero())
            }

            HStack(spacing: 12) {
                FWButton(title: "Save to Photos", icon: "square.and.arrow.down") {
                    // TODO: Save to Photos
                }

                Button {
                    // share handled by ShareLink
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FW.Color.ink)
                        .frame(width: 54, height: 54)
                        .background(FW.Color.surface2)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, FW.Spacing.md)
        }
        .padding(.top, 20)
    }

    private var failedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(viewModel.errorMessage ?? "Something went wrong")
                .font(FW.Font.body())
                .multilineTextAlignment(.center)
                .foregroundStyle(FW.Color.ink2)

            FWButton(title: "Try Again", icon: "arrow.clockwise") {
                Task {
                    await viewModel.generate(for: child, style: style, context: modelContext)
                }
            }
            .padding(.horizontal, FW.Spacing.xl)

            Spacer()
        }
        .padding(.horizontal, FW.Spacing.md)
    }
}
