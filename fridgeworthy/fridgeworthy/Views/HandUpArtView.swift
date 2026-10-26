import Photos
import SwiftData
import SwiftUI
import UIKit

struct HandUpArtView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onAddArtwork: (Date, Child?) -> Void

    @State private var selectedChildID: UUID?
    @State private var periodKind: ArtworkPeriodKind = .week
    @State private var anchorDate = Date()
    @State private var originalPreview: UIImage?
    @State private var isRendering = false
    @State private var isSaving = false
    @State private var isSaved = false
    @State private var errorMessage: String?
    @State private var showStylePicker = false
    @State private var selectedStyle: StyleTemplate?
    @State private var showStyledWallpaper = false
    @State private var galleryViewModel = GalleryViewModel()

    private var selectedChild: Child? {
        children.first { $0.id == selectedChildID } ?? children.first
    }

    private var period: ArtworkPeriod {
        ArtworkPeriod(kind: periodKind, anchor: anchorDate)
    }

    private var artworks: [Artwork] {
        (selectedChild?.artworks ?? [])
            .filter { period.contains($0.createdAt) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var periodTitle: String {
        if periodKind == .month {
            return period.start.formatted(.dateTime.month(.wide).year())
        }
        let lastDay = period.end.addingTimeInterval(-1)
        return "\(period.start.formatted(.dateTime.month(.abbreviated).day())) – \(lastDay.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                introduction
                childSelector
                periodSelector
                collectionSection
                if !artworks.isEmpty {
                    wallpaperSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 42)
        }
        .background(FWPaperBackground())
        .refreshable {
            if let selectedChild {
                await galleryViewModel.syncWithRemote(child: selectedChild, context: modelContext)
            }
        }
        .navigationTitle("Hand up art")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(FW.Color.onboardingInk)
            }
        }
        .sheet(isPresented: $showStylePicker) {
            if let child = selectedChild {
                StylePickerView(child: child) { style in
                    selectedStyle = style
                    showStylePicker = false
                    showStyledWallpaper = true
                }
            }
        }
        .navigationDestination(isPresented: $showStyledWallpaper) {
            if let child = selectedChild, let selectedStyle {
                WallpaperView(child: child, style: selectedStyle, period: period)
            }
        }
        .alert("Couldn't finish", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .onChange(of: selectedChildID) { _, _ in resetPreview() }
        .onChange(of: periodKind) { _, _ in resetPreview() }
        .onChange(of: anchorDate) { _, _ in resetPreview() }
        .task(id: selectedChild?.id) {
            if let selectedChild {
                await galleryViewModel.syncWithRemote(child: selectedChild, context: modelContext)
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The art they made.\nA moment you can keep.")
                .font(FW.Font.heroDisplay(32))
                .foregroundStyle(FW.Color.onboardingInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("Gather a week or month of artwork, then make a wallpaper for your phone.")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)
        }
    }

    private var childSelector: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionLabel("LITTLE ARTIST")
            if children.isEmpty {
                Text("Add a child and their artwork to start a collection.")
                    .font(FW.Font.body(15))
                    .foregroundStyle(FW.Color.ink3)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(children) { child in
                            FWChildChip(
                                emoji: child.avatarEmoji,
                                name: child.name,
                                isActive: selectedChild?.id == child.id
                            ) {
                                selectedChildID = child.id
                            }
                        }
                    }
                }
                .disabled(isRendering)
            }
        }
    }

    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("CHOOSE A COLLECTION")
            Picker("Collection period", selection: $periodKind) {
                ForEach(ArtworkPeriodKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isRendering)

            HStack {
                Button {
                    anchorDate = period.shifted(by: -1).anchor
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous \(periodKind.rawValue.lowercased())")
                .disabled(isRendering)

                Spacer()
                Text(periodTitle)
                    .font(FW.Font.body(16, weight: .semibold))
                    .foregroundStyle(FW.Color.ink)
                Spacer()

                Button {
                    anchorDate = period.shifted(by: 1).anchor
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .disabled(period.shifted(by: 1).start > Date() || isRendering)
                .accessibilityLabel("Next \(periodKind.rawValue.lowercased())")
            }

            .foregroundStyle(FW.Color.onboardingInk)
        }
    }

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("ORIGINAL ARTWORK")
                Spacer()
                Text("\(artworks.count) piece\(artworks.count == 1 ? "" : "s")")
                    .font(FW.Font.caption(13))
                    .foregroundStyle(FW.Color.ink3)
            }

            if galleryViewModel.isLoading {
                ProgressView("Refreshing artwork…")
                    .font(FW.Font.caption(13))
            }

            if let syncError = galleryViewModel.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(FW.Color.primary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Couldn't refresh this collection")
                            .font(FW.Font.caption(14, weight: .semibold))
                        Text(syncError)
                            .font(FW.Font.caption(13))
                            .foregroundStyle(FW.Color.ink3)
                        Button("Try again") {
                            if let selectedChild {
                                Task {
                                    await galleryViewModel.syncWithRemote(child: selectedChild, context: modelContext)
                                }
                            }
                        }
                        .font(FW.Font.caption(13, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(FW.Color.lavender)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if artworks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 34))
                        .foregroundStyle(FW.Color.primary)
                    Text("No artwork in this \(periodKind.rawValue.lowercased()) yet")
                        .font(FW.Font.body(16, weight: .semibold))
                    Text("Add a piece now or browse another \(periodKind.rawValue.lowercased()).")
                        .font(FW.Font.caption(14))
                        .foregroundStyle(FW.Color.ink3)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(FW.Color.card)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(artworks) { artwork in
                            artworkTile(artwork)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                onAddArtwork(min(anchorDate, Date()), selectedChild)
            } label: {
                Label("Add artwork", systemImage: "plus")
                    .font(FW.Font.body(15, weight: .semibold))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(FW.Color.card)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(FW.Color.border))
            }
            .buttonStyle(.plain)
        }
    }

    private func artworkTile(_ artwork: Artwork) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let localImage = localImage(for: artwork) {
                    Image(uiImage: localImage).resizable().scaledToFill()
                } else if let remote = artwork.remoteImageURL, let url = URL(string: remote) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(FW.Color.lavender)
                    }
                } else {
                    Rectangle().fill(FW.Color.lavender)
                        .overlay(Image(systemName: "photo").foregroundStyle(FW.Color.ink3))
                }
            }
            .frame(width: 126, height: 136)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 15))

            Text(artwork.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(FW.Font.caption(12))
                .foregroundStyle(FW.Color.ink3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Artwork from \(artwork.createdAt.formatted(.dateTime.month(.wide).day()))")
    }

    private var wallpaperSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("MAKE IT A WALLPAPER")
            Text("Choose how to remember this collection.")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)

            choiceCard(
                icon: "square.grid.2x2",
                title: "Original collage",
                detail: "Every original piece, arranged together."
            ) {
                Task { await makeOriginalPreview() }
            }

            choiceCard(
                icon: "sparkles",
                title: "Styled wallpaper",
                detail: "A new scene inspired by their art’s colors and story."
            ) {
                showStylePicker = true
            }

            if isRendering {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Arranging the original artwork…")
                        .font(FW.Font.caption(14))
                }
                .foregroundStyle(FW.Color.ink3)
                .frame(maxWidth: .infinity)
            }

            if let originalPreview {
                originalResult(originalPreview)
            }
        }
    }

    private func choiceCard(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(FW.Color.primary)
                    .frame(width: 48, height: 48)
                    .background(FW.Color.lavender)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(FW.Font.body(16, weight: .semibold))
                        .foregroundStyle(FW.Color.ink)
                    Text(detail)
                        .font(FW.Font.caption(13))
                        .foregroundStyle(FW.Color.ink3)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(FW.Color.ink3)
            }
            .padding(15)
            .background(FW.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .modifier(FW.Shadow.cardSoft())
        }
        .buttonStyle(.plain)
        .disabled(isRendering)
    }

    private func originalResult(_ image: UIImage) -> some View {
        VStack(spacing: 14) {
            Text("Original collage preview")
                .font(FW.Font.body(16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 216, height: 440)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .frame(maxWidth: .infinity)

            FWButton(title: isSaved ? "Saved to Photos" : isSaving ? "Saving…" : "Save to Photos", icon: isSaved ? "checkmark" : "square.and.arrow.down") {
                Task { await saveOriginal(image) }
            }
            .disabled(isSaving || isSaved)

            Text("After saving, choose this image in your device’s wallpaper settings.")
                .font(FW.Font.caption(13))
                .foregroundStyle(FW.Color.ink3)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .background(FW.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(FW.Font.micro(12))
            .tracking(1)
            .foregroundStyle(FW.Color.ink3)
    }

    private func localImage(for artwork: Artwork) -> UIImage? {
        guard !artwork.localImagePath.isEmpty else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return UIImage(contentsOfFile: documents.appendingPathComponent(artwork.localImagePath).path)
    }

    private func image(for artwork: Artwork) async throws -> UIImage {
        if let image = localImage(for: artwork) { return image }

        let urlString: String
        if let storagePath = artwork.storagePath {
            urlString = try await SupabaseService.shared.signedArtworkURL(path: storagePath)
        } else if let remoteImageURL = artwork.remoteImageURL {
            urlString = remoteImageURL
        } else {
            throw ArtworkImageError.unavailable
        }

        guard let url = URL(string: urlString) else { throw ArtworkImageError.unavailable }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw ArtworkImageError.unavailable }
        return image
    }

    private func makeOriginalPreview() async {
        guard !artworks.isEmpty, let child = selectedChild else { return }
        isRendering = true
        defer { isRendering = false }
        do {
            var images: [UIImage] = []
            for artwork in artworks {
                images.append(try await image(for: artwork))
            }
            let title = "\(child.name)’s art · \(periodTitle)"
            guard let result = ArtworkCollageRenderer.render(images: images, title: title) else {
                throw ArtworkImageError.unavailable
            }
            originalPreview = result
            isSaved = false
        } catch {
            errorMessage = "Couldn't load every artwork photo. Check your connection and try again."
        }
    }

    private func saveOriginal(_ image: UIImage) async {
        isSaving = true
        defer { isSaving = false }
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let granted: Bool
        switch status {
        case .authorized, .limited:
            granted = true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            granted = newStatus == .authorized || newStatus == .limited
        default:
            granted = false
        }
        guard granted else {
            errorMessage = "Allow Photos access in Settings to save this wallpaper."
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
            isSaved = true
        } catch {
            errorMessage = "Couldn't save the wallpaper to Photos. Please try again."
        }
    }

    private func resetPreview() {
        originalPreview = nil
        isSaved = false
    }
}

private enum ArtworkImageError: Error {
    case unavailable
}
