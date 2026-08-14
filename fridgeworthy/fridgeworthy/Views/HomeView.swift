import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var profiles: [UserProfile]
    @State private var showAddChild = false
    @State private var newChildName = ""
    @State private var selectedChild: Child?
    @State private var stylePickerChild: Child?
    @State private var wallpaperFlow: WallpaperFlow?

    struct WallpaperFlow: Hashable {
        let child: Child
        let style: StyleTemplate

        static func == (lhs: WallpaperFlow, rhs: WallpaperFlow) -> Bool {
            lhs.child.id == rhs.child.id && lhs.style.id == rhs.style.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(child.id)
            hasher.combine(style.id)
        }
    }

    private var userProfile: UserProfile? { profiles.first }

    private var filteredArtworks: [Artwork] {
        let artworks: [Artwork]
        if let child = selectedChild {
            artworks = child.artworks
        } else {
            artworks = children.flatMap(\.artworks)
        }
        return artworks.sorted { $0.createdAt > $1.createdAt }
    }

    private var featuredArtwork: Artwork? { filteredArtworks.first }
    private var recentArtworks: [Artwork] { Array(filteredArtworks.dropFirst().prefix(10)) }
    private var totalPieces: Int { children.flatMap(\.artworks).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greetingSection
                    .padding(.top, 16)
                childChipRail

                if children.isEmpty {
                    emptyState
                } else {
                    if let featured = featuredArtwork {
                        featuredSection(featured)
                    }
                    if !recentArtworks.isEmpty {
                        recentSection
                    }
                }
            }
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .clipped()
        .background(FW.Color.bg)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Add a Child", isPresented: $showAddChild) {
            TextField("Child's name", text: $newChildName)
            Button("Add") { addChild() }
            Button("Cancel", role: .cancel) { newChildName = "" }
        } message: {
            Text("Enter your child's name to get started")
        }
        .sheet(item: $stylePickerChild) { child in
            StylePickerView(child: child) { style in
                stylePickerChild = nil
                wallpaperFlow = WallpaperFlow(child: child, style: style)
            }
        }
        .navigationDestination(item: $wallpaperFlow) { flow in
            WallpaperView(child: flow.child, style: flow.style)
        }
        .onAppear {
            if userProfile == nil {
                ensureProfile()
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hi, \(userProfile?.greeting ?? "there")")
                .font(FW.Font.heroDisplay())
                .tracking(-0.7)

            Text("\(children.count) kid\(children.count == 1 ? "" : "s") · \(totalPieces) piece\(totalPieces == 1 ? "" : "s")")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)
        }
        .padding(.horizontal, FW.Spacing.md)
    }

    // MARK: - Child Chip Rail

    private var childChipRail: some View {
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

                // Add child button
                Button {
                    showAddChild = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FW.Color.ink3)
                        .frame(width: 36, height: 36)
                        .background(FW.Color.card)
                        .clipShape(Circle())
                        .modifier(FW.Shadow.cardSoft())
                }
            }
            .padding(.horizontal, FW.Spacing.md)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.wave")
                .font(.system(size: 48))
                .foregroundStyle(FW.Color.accent.opacity(0.4))

            Text("Welcome to Fridgeworthy!")
                .font(FW.Font.sectionTitle())

            Text("Add your child to start turning\ntheir artwork into wallpapers")
                .font(FW.Font.body())
                .foregroundStyle(FW.Color.ink3)
                .multilineTextAlignment(.center)

            FWButton(title: "Add Child", icon: "plus", style: .primary) {
                showAddChild = true
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, FW.Spacing.md)
    }

    // MARK: - Featured Section

    private func featuredSection(_ artwork: Artwork) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Eyebrow
            Text("FEATURED THIS WEEK")
                .font(FW.Font.micro())
                .tracking(1.2)
                .foregroundStyle(FW.Color.accent)
                .padding(.horizontal, FW.Spacing.md)

            // Featured card
            VStack(alignment: .leading, spacing: 0) {
                // Artwork image area
                ZStack(alignment: .bottomLeading) {
                    featuredArtworkImage(artwork)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .background(
                            LinearGradient(
                                colors: [FW.Color.cream1, FW.Color.cream2],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipped()

                    // Glass caption
                    if let child = artwork.child {
                        FWGlassCaptionPill(text: childAgeLabel(child).isEmpty ? child.name : "\(child.name), \(childAgeLabel(child))")
                            .padding(12)
                    }
                }

                // Card body
                VStack(alignment: .leading, spacing: 8) {
                    Text(artwork.title ?? "Untitled Artwork")
                        .font(FW.Font.cardTitle)
                        .tracking(-0.5)

                    if let desc = artwork.artworkDescription {
                        Text(desc)
                            .font(FW.Font.caption(13))
                            .foregroundStyle(FW.Color.ink3)
                            .lineLimit(1)
                    }

                    HStack(spacing: 12) {
                        FWButton(title: "Make wallpaper", icon: "wand.and.stars", style: .primary) {
                            stylePickerChild = artwork.child
                        }

                        if let url = shareURL(for: artwork) {
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 17))
                                    .foregroundStyle(FW.Color.ink)
                                    .frame(width: 44, height: 44)
                                    .background(FW.Color.surface2)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(FW.Spacing.md)
            }
            .background(FW.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: FW.Radius.cardLg, style: .continuous))
            .modifier(FW.Shadow.cardHero())
            .padding(.horizontal, FW.Spacing.md)
        }
    }

    @ViewBuilder
    private func featuredArtworkImage(_ artwork: Artwork) -> some View {
        if let localImage = loadLocalImage(artwork) {
            Color.clear
                .overlay {
                    Image(uiImage: localImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
        } else if let remoteURL = artwork.remoteImageURL, let url = URL(string: remoteURL) {
            Color.clear
                .overlay {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                }
                .clipped()
        } else {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 48))
                .foregroundStyle(FW.Color.accent.opacity(0.2))
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                Button("See all") {}
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(FW.Color.accent)
            }
            .padding(.horizontal, FW.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentArtworks) { artwork in
                        recentThumbnail(artwork)
                    }
                }
                .padding(.horizontal, FW.Spacing.md)
            }
        }
    }

    private func recentThumbnail(_ artwork: Artwork) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .frame(width: 130, height: 130)
                .overlay {
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
                .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnail, style: .continuous))

            Text(artwork.title ?? "Untitled")
                .font(FW.Font.caption(13, weight: .medium))
                .foregroundStyle(FW.Color.ink)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private func childAgeLabel(_ child: Child) -> String {
        child.ageText ?? ""
    }

    private func loadLocalImage(_ artwork: Artwork) -> UIImage? {
        guard !artwork.localImagePath.isEmpty else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(artwork.localImagePath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func shareURL(for artwork: Artwork) -> URL? {
        if !artwork.localImagePath.isEmpty {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(artwork.localImagePath)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }
        if let remote = artwork.remoteImageURL {
            return URL(string: remote)
        }
        return nil
    }

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        let profile = UserProfile(supabaseID: authService.currentUserID?.uuidString ?? UUID().uuidString)
        modelContext.insert(profile)
    }

    private func addChild() {
        let trimmed = newChildName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let child = Child(name: trimmed)
        modelContext.insert(child)
        newChildName = ""

        guard let profileID = authService.currentUserID else { return }
        Task {
            _ = try? await SupabaseService.shared.insertChild(
                id: child.id,
                name: trimmed,
                profileID: profileID
            )
        }
    }
}
