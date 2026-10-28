import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Main navigation container with floating tab bar.
struct MainTabView: View {
    @State private var selectedTab: FWTab = .home
    @State private var showSettingsSheet = false
    @State private var showHandUpArt = false
    @State private var handUpCaptureDate: Date?
    @State private var handUpCaptureChildID: UUID?
    @State private var showAddArtworkSheet = false
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var capturedImage: UIImage?
    @State private var reviewItem: ArtworkReviewItem?
    @State private var libraryItem: PhotosPickerItem?
    @State private var captureRequiresChild = false
    @State private var addChildRequestToken: UUID?
    @State private var memoryDate = Date()
    @State private var memoryChild: Child?
    @State private var pendingImages: [PendingArtworkPhoto] = []
    @State private var photoTargetDate = Date()
    @State private var photoTargetChild: Child?
    @State private var isMemoryNoteFocused = false
    @Query(sort: \Child.createdAt) private var children: [Child]

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView(
                            addChildRequestToken: addChildRequestToken,
                            onSelectDate: openMemory,
                            onOpenHandUpArt: { showHandUpArt = true }
                        )
                    }
                case .capture:
                    DailyMemoryView(
                        initialDate: memoryDate,
                        initialChild: memoryChild,
                        pendingImages: $pendingImages,
                        onRequestPhoto: beginAdditionalPhoto,
                        onDisplayedDateChanged: { photoTargetDate = $0 },
                        onNoteFocusChanged: { isMemoryNoteFocused = $0 }
                    )
                    .id(memoryRouteID)
                case .settings:
                    Color.clear
                }
            }
            // Reserve space for the tab bar only while it is visible.
            .safeAreaPadding(.bottom, isMemoryNoteFocused ? 0 : 80)
            .animation(.spring(response: 0.38, dampingFraction: 0.86), value: isMemoryNoteFocused)

            if DailyMemoryNavigation.showsBottomNavigation(
                isNoteFocused: isMemoryNoteFocused
            ) {
                FWTabBar(selectedTab: $selectedTab, onSettingsTap: {
                    showSettingsSheet = true
                }) {
                    beginCapture()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showAddArtworkSheet {
                FWAddArtworkSheet(
                    targetDate: photoTargetDate,
                    children: children,
                    selectedChildID: photoTargetChild?.id,
                    onSelectChild: { photoTargetChild = $0 },
                    onDismiss: dismissAddArtworkSheet,
                    onCamera: chooseCamera,
                    onLibrary: chooseLibrary
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            NavigationStack {
                MeView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHandUpArt, onDismiss: {
            if let date = handUpCaptureDate {
                handUpCaptureDate = nil
                beginHandUpCapture(date: date, childID: handUpCaptureChildID)
                handUpCaptureChildID = nil
            }
        }) {
            NavigationStack {
                HandUpArtView { date, child in
                    handUpCaptureDate = date
                    handUpCaptureChildID = child?.id
                    showHandUpArt = false
                }
            }
        }
        .alert("Add a child first", isPresented: $captureRequiresChild) {
            Button("Add Child") {
                selectedTab = .home
                addChildRequestToken = UUID()
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Artwork needs a little artist before it can be added to the family calendar.")
        }
        .alert("Camera unavailable", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The camera is not available on this device. You can still choose artwork from the photo library.")
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $libraryItem, matching: .images, preferredItemEncoding: .current)
        .onChange(of: libraryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    reviewItem = ArtworkReviewItem(image: image, originalData: data)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if let capturedImage {
                if let data = capturedImage.pngData() {
                    reviewItem = ArtworkReviewItem(image: capturedImage, originalData: data)
                }
                self.capturedImage = nil
            }
        }) {
            CameraView { image in
                capturedImage = image
            }
        }
        .sheet(item: $reviewItem) { item in
            ArtworkReviewView(item: item) { photo in
                accept(photo)
                reviewItem = nil
            }
        }
    }

    @State private var showLibraryPicker = false

    private var memoryRouteID: String {
        let day = Calendar.current.startOfDay(for: memoryDate).timeIntervalSinceReferenceDate
        return "\(day)-\(memoryChild?.id.uuidString ?? "all")"
    }

    private func beginCapture() {
        guard !children.isEmpty else {
            selectedTab = .home
            captureRequiresChild = true
            return
        }
        photoTargetDate = DailyMemoryNavigation.addArtworkTargetDate(
            isViewingMemory: selectedTab == .capture,
            displayedDate: photoTargetDate
        )
        photoTargetChild = nil
        presentArtworkSourcePicker()
    }

    private func beginAdditionalPhoto(for date: Date) {
        guard !children.isEmpty else {
            selectedTab = .home
            captureRequiresChild = true
            return
        }
        photoTargetDate = date
        photoTargetChild = nil
        presentArtworkSourcePicker()
    }

    private func beginHandUpCapture(date: Date, childID: UUID?) {
        guard !children.isEmpty else {
            selectedTab = .home
            captureRequiresChild = true
            return
        }
        photoTargetDate = date
        photoTargetChild = children.first { $0.id == childID }
        presentArtworkSourcePicker()
    }

    private func presentArtworkSourcePicker() {
        withAnimation(.easeOut(duration: 0.2)) {
            showAddArtworkSheet = true
        }
    }

    private func openMemory(date: Date, child: Child?) {
        memoryDate = date
        memoryChild = child
        photoTargetDate = date
        pendingImages.removeAll()
        withAnimation(.easeOut(duration: 0.18)) {
            selectedTab = .capture
        }
    }

    private func accept(_ photo: PendingArtworkPhoto) {
        memoryDate = photoTargetDate
        memoryChild = photoTargetChild
        pendingImages.append(photo)
        libraryItem = nil
        withAnimation(.easeOut(duration: 0.18)) {
            selectedTab = .capture
        }
    }

    private func dismissAddArtworkSheet() {
        withAnimation(.easeOut(duration: 0.2)) {
            showAddArtworkSheet = false
        }
    }

    private func chooseCamera() {
        dismissAddArtworkSheet()
        if cameraAvailable {
            showCamera = true
        } else {
            showCameraUnavailable = true
        }
    }

    private func chooseLibrary() {
        dismissAddArtworkSheet()
        libraryItem = nil
        showLibraryPicker = true
    }
}

private struct FWAddArtworkSheet: View {
    let targetDate: Date
    let children: [Child]
    let selectedChildID: UUID?
    let onSelectChild: (Child) -> Void
    let onDismiss: () -> Void
    let onCamera: () -> Void
    let onLibrary: () -> Void

    private var orderedChildIDs: [UUID] { children.map(\.id) }

    private var targetDateLabel: String {
        Calendar.current.isDateInToday(targetDate)
            ? "Today"
            : targetDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private var childPickerHeight: CGFloat {
        let rowCount = (children.count + 1) / 2
        let rowHeight: CGFloat = 42
        let rowSpacing: CGFloat = 8
        let contentHeight = CGFloat(rowCount) * rowHeight
            + CGFloat(max(0, rowCount - 1)) * rowSpacing
        return min(contentHeight, 128)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 18) {
                Capsule()
                    .fill(FW.Color.onboardingInk.opacity(0.2))
                    .frame(width: 42, height: 5)

                Text("Add artwork to \(targetDateLabel)")
                    .font(FW.Font.body(16))
                    .foregroundStyle(FW.Color.onboardingInk)

                Text("Choose a child")
                    .font(FW.Font.caption(13))
                    .foregroundStyle(FW.Color.onboardingInk.opacity(0.62))

                ScrollView(.vertical) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(children) { child in
                            childChoice(child)
                        }
                    }
                    .modifier(FWSelectionLayoutAnimation(selection: selectedChildID))
                }
                .frame(height: childPickerHeight)
                .scrollIndicators(.hidden)

                HStack(spacing: 16) {
                    artworkAction(
                        asset: "FWActionCamera",
                        title: "Take Photo",
                        action: onCamera
                    )

                    artworkAction(
                        asset: "FWActionGallery",
                        title: "Choose from Library",
                        action: onLibrary
                    )
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(FW.Color.bg)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 30,
                    topTrailingRadius: 30,
                    style: .continuous
                )
            )
            .shadow(color: FW.Color.onboardingInk.opacity(0.12), radius: 22, y: -6)
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAddTraits(.isModal)
    }

    private func childChoice(_ child: Child) -> some View {
        let isSelected = selectedChildID == child.id
        let color = FW.Color.childColor(
            id: child.id,
            orderedChildIDs: orderedChildIDs,
            customIndex: child.colorIndex
        )

        return FWAnimatedSelectionChip(
            name: child.name,
            colorTint: color,
            isActive: isSelected,
            onTap: { onSelectChild(child) },
            font: FW.Font.body(14),
            horizontalPadding: 12,
            verticalPadding: 12,
            fillsWidth: true,
            inactiveFillOpacity: 0.36
        )
        .frame(height: 42)
    }

    private func artworkAction(
        asset: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(FW.Color.onboardingInk)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .frame(height: 126)
                .background(FW.Color.onboardingInk.opacity(0.055))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(FW.Color.onboardingInk.opacity(0.1), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .disabled(selectedChildID == nil)
        .opacity(selectedChildID == nil ? 0.45 : 1)
    }
}
