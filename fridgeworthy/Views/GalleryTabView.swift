import SwiftUI
import SwiftData

struct GalleryTabView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @State private var selectedChild: Child?

    private var allArtworks: [Artwork] {
        let artworks: [Artwork]
        if let child = selectedChild {
            artworks = child.artworks
        } else {
            artworks = children.flatMap(\.artworks)
        }
        return artworks.sorted { $0.createdAt > $1.createdAt }
    }

    private var groupedByMonth: [(key: String, artworks: [Artwork])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: allArtworks) { formatter.string(from: $0.createdAt) }
        return grouped.sorted { $0.value.first?.createdAt ?? .distantPast > $1.value.first?.createdAt ?? .distantPast }
            .map { (key: $0.key, artworks: $0.value) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gallery")
                        .font(FW.Font.largeTitle)
                        .tracking(-0.9)

                    Text("\(allArtworks.count) piece\(allArtworks.count == 1 ? "" : "s") from \(children.count) kid\(children.count == 1 ? "" : "s")")
                        .font(FW.Font.body(15))
                        .foregroundStyle(FW.Color.ink3)
                }
                .padding(.horizontal, FW.Spacing.md)

                // Child filter rail
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FWAllChip(isActive: selectedChild == nil) {
                            selectedChild = nil
                        }
                        ForEach(children) { child in
                            FWChildChip(
                                emoji: child.avatarEmoji,
                                name: child.name,
                                isActive: selectedChild?.id == child.id
                            ) {
                                selectedChild = child
                            }
                        }
                    }
                    .padding(.horizontal, FW.Spacing.md)
                }

                // Month sections
                if allArtworks.isEmpty {
                    ContentUnavailableView {
                        Label("No Artwork Yet", systemImage: "paintpalette")
                    } description: {
                        Text("Capture your first masterpiece!")
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(groupedByMonth, id: \.key) { section in
                        monthSection(title: section.key, artworks: section.artworks)
                    }
                }
            }
            .padding(.top, FW.Spacing.md)
            .padding(.bottom, 32)
        }
        .background(FW.Color.bg)
    }

    private func monthSection(title: String, artworks: [Artwork]) -> some View {
        let parts = title.split(separator: " ")
        let month = String(parts.first ?? "")
        let year = String(parts.last ?? "")

        return VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(month)
                            .font(FW.Font.sectionTitle(24))
                            .tracking(-0.6)
                        Text(year)
                            .font(FW.Font.body(15))
                            .foregroundStyle(FW.Color.ink3)
                    }
                    FWCrayonUnderline(width: CGFloat(month.count) * 12, height: 6)
                }

                Spacer()

                Text("\(artworks.count) piece\(artworks.count == 1 ? "" : "s")")
                    .font(FW.Font.caption(13, weight: .medium))
                    .foregroundStyle(FW.Color.ink3)
            }
            .padding(.horizontal, FW.Spacing.md)

            // Grid
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(artworks) { artwork in
                    galleryThumbnail(artwork)
                }
            }
            .padding(.horizontal, FW.Spacing.md)
        }
    }

    private func galleryThumbnail(_ artwork: Artwork) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let localImage = loadLocalImage(artwork) {
                    Image(uiImage: localImage)
                        .resizable()
                        .scaledToFill()
                } else if let remoteURL = artwork.remoteImageURL, let url = URL(string: remoteURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(FW.Color.cream1)
                    }
                } else {
                    Rectangle().fill(FW.Color.cream1)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(FW.Color.ink4)
                        }
                }
            }
            .frame(minHeight: 110)
            .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous))

            // Kid emoji badge
            if let child = artwork.child {
                Text(child.avatarEmoji)
                    .font(.system(size: 11))
                    .frame(width: 18, height: 18)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(6)
            }
        }
        .background(FW.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous))
        .modifier(FW.Shadow.cardSoft())
    }

    private func loadLocalImage(_ artwork: Artwork) -> UIImage? {
        guard !artwork.localImagePath.isEmpty else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(artwork.localImagePath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}
