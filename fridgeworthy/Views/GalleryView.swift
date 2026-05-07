import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GalleryViewModel()

    let child: Child

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        Group {
            if viewModel.artworks.isEmpty {
                emptyState
            } else {
                artworkGrid
            }
        }
        .navigationTitle("\(child.name)'s Art")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: CaptureView(child: child)) {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.syncWithRemote(child: child, context: modelContext)
        }
        .onAppear {
            viewModel.loadArtworks(for: child)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Artwork Yet", systemImage: "paintpalette")
        } description: {
            Text("Photograph your kid's first masterpiece!")
        } actions: {
            NavigationLink(destination: CaptureView(child: child)) {
                Text("Add Artwork")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var artworkGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(viewModel.artworks) { artwork in
                    ArtworkCell(artwork: artwork)
                }
            }
            .padding(FW.Spacing.md)
        }
    }
}

struct ArtworkCell: View {
    let artwork: Artwork

    var body: some View {
        Group {
            if let localImage = loadLocalImage() {
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minHeight: 110)
                    .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous))
            } else if let remoteURL = artwork.remoteImageURL, let url = URL(string: remoteURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(minHeight: 110)
                .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous)
                    .fill(FW.Color.cream1)
                    .frame(minHeight: 110)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(FW.Color.ink4)
                    }
            }
        }
        .background(FW.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous))
        .modifier(FW.Shadow.cardSoft())
    }

    private func loadLocalImage() -> UIImage? {
        guard !artwork.localImagePath.isEmpty else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(artwork.localImagePath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}
