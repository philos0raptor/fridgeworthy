import SwiftUI
import SwiftData

struct ChildDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let child: Child
    @State private var selectedSegment = 0
    @State private var selectedStyle: StyleTemplate?
    @State private var showStylePicker = false
    @State private var showWallpaperView = false

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Amber gradient hero
                heroSection

                // White sheet content
                sheetContent
                    .background(FW.Color.card)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: FW.Radius.sheet,
                            topTrailingRadius: FW.Radius.sheet
                        )
                    )
                    .offset(y: -28)
            }
        }
        .background(FW.Color.bg)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .sheet(isPresented: $showStylePicker) {
            StylePickerView(child: child) { style in
                selectedStyle = style
                showStylePicker = false
                showWallpaperView = true
            }
        }
        .navigationDestination(isPresented: $showWallpaperView) {
            if let style = selectedStyle {
                WallpaperView(child: child, style: style)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .top) {
            // Amber gradient
            LinearGradient(
                colors: [FW.Color.amberHero1, FW.Color.amberHero2, FW.Color.amberHero3],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 380)
            .overlay { PaperTexture(opacity: 0.25) }

            VStack(spacing: 0) {
                // Nav buttons
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassSurface(cornerRadius: 20)
                    }

                    Spacer()

                    Button { showStylePicker = true } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassSurface(cornerRadius: 20)
                    }
                }
                .padding(.horizontal, FW.Spacing.md)
                .padding(.top, 56)

                // Avatar + info
                HStack(spacing: 16) {
                    Circle()
                        .fill(.white)
                        .frame(width: 88, height: 88)
                        .overlay {
                            Text(child.avatarEmoji)
                                .font(.system(size: 40))
                        }
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 32, weight: .heavy))
                            .tracking(-0.7)
                            .foregroundStyle(Color(hex: 0x2A1A05))

                        Text("Since \(child.createdAt.formatted(.dateTime.month(.abbreviated).year()))")
                            .font(FW.Font.body(15))
                            .foregroundStyle(Color(hex: 0x2A1A05).opacity(0.7))
                    }
                }
                .padding(.horizontal, FW.Spacing.lg)
                .padding(.top, 20)

                // Stat chips
                HStack(spacing: 10) {
                    statChip(value: "\(child.artworks.count)", label: "Artworks")
                    statChip(value: "\(child.wallpapers.count)", label: "Wallpapers")
                    statChip(value: ageSinceCreated, label: "Active")
                }
                .padding(.horizontal, FW.Spacing.md)
                .padding(.top, 20)
            }
        }
        .frame(height: 380)
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(FW.Font.statNumeric)
                .foregroundStyle(.white)
            Text(label)
                .font(FW.Font.caption(12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassSurface(cornerRadius: FW.Radius.statChip)
    }

    private var ageSinceCreated: String {
        let months = Calendar.current.dateComponents([.month], from: child.createdAt, to: Date()).month ?? 0
        if months < 1 { return "New" }
        if months < 12 { return "\(months)mo" }
        return "\(months / 12)yr"
    }

    // MARK: - Sheet Content

    private var sheetContent: some View {
        VStack(spacing: 20) {
            // Segmented control
            Picker("Filter", selection: $selectedSegment) {
                Text("All").tag(0)
                Text("Wallpapers").tag(1)
                Text("Prints").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, FW.Spacing.md)
            .padding(.top, FW.Spacing.lg)

            // Artwork grid
            if child.artworks.isEmpty {
                ContentUnavailableView {
                    Label("No Artwork Yet", systemImage: "paintpalette")
                } description: {
                    Text("Capture \(child.name)'s first masterpiece!")
                }
                .padding(.top, 40)
            } else {
                artworkGridSections
            }
        }
        .padding(.bottom, 32)
    }

    private var artworkGridSections: some View {
        let sorted = child.artworks.sorted { $0.createdAt > $1.createdAt }
        let thisWeek = sorted.filter { Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }
        let older = sorted.filter { !Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }

        return VStack(alignment: .leading, spacing: 24) {
            if !thisWeek.isEmpty {
                gridSection(title: "THIS WEEK", artworks: thisWeek)
            }
            if !older.isEmpty {
                gridSection(title: "EARLIER", artworks: older)
            }
        }
    }

    private func gridSection(title: String, artworks: [Artwork]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(FW.Font.micro(13))
                .tracking(0.8)
                .foregroundStyle(FW.Color.ink3)
                .padding(.horizontal, FW.Spacing.md)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(artworks) { artwork in
                    thumbnailCell(artwork)
                }
            }
            .padding(.horizontal, FW.Spacing.md)
        }
    }

    private func thumbnailCell(_ artwork: Artwork) -> some View {
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
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnailLg, style: .continuous))
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
