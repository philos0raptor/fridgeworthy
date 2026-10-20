import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Main navigation container with floating tab bar.
struct MainTabView: View {
    @State private var selectedTab: FWTab = .home
    @State private var showAddArtworkSheet = false
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var capturedImage: UIImage?
    @State private var libraryItem: PhotosPickerItem?
    @State private var captureRequiresChild = false
    @State private var addChildRequestToken: UUID?
    @State private var memoryDate = Date()
    @State private var memoryChild: Child?
    @State private var pendingImages: [UIImage] = []
    @State private var photoTargetDate = Date()
    @State private var photoTargetChild: Child?
    @Query private var children: [Child]

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
                            onSelectDate: openMemory
                        )
                    }
                case .capture:
                    DailyMemoryView(
                        initialDate: memoryDate,
                        initialChild: memoryChild,
                        pendingImages: $pendingImages,
                        onRequestPhoto: beginAdditionalPhoto
                    )
                    .id(memoryRouteID)
                case .settings:
                    NavigationStack {
                        MeView()
                    }
                }
            }
            // Extra bottom padding so content doesn't hide behind tab bar
            .safeAreaPadding(.bottom, 80)

            FWTabBar(selectedTab: $selectedTab) {
                beginCapture()
            }

            if showAddArtworkSheet {
                FWAddArtworkSheet(
                    onDismiss: dismissAddArtworkSheet,
                    onCamera: chooseCamera,
                    onLibrary: chooseLibrary
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
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
        .photosPicker(isPresented: $showLibraryPicker, selection: $libraryItem, matching: .images)
        .onChange(of: libraryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    accept(image)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if let capturedImage {
                accept(capturedImage)
                self.capturedImage = nil
            }
        }) {
            CameraView { image in
                capturedImage = image
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
        photoTargetDate = Date()
        photoTargetChild = children.first
        presentArtworkSourcePicker()
    }

    private func beginAdditionalPhoto(for date: Date) {
        guard !children.isEmpty else {
            selectedTab = .home
            captureRequiresChild = true
            return
        }
        photoTargetDate = date
        photoTargetChild = memoryChild ?? children.first
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
        pendingImages.removeAll()
        withAnimation(.easeOut(duration: 0.18)) {
            selectedTab = .capture
        }
    }

    private func accept(_ image: UIImage) {
        memoryDate = photoTargetDate
        memoryChild = photoTargetChild
        pendingImages.append(image)
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
    let onDismiss: () -> Void
    let onCamera: () -> Void
    let onLibrary: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 22) {
                Capsule()
                    .fill(FW.Color.onboardingInk.opacity(0.2))
                    .frame(width: 42, height: 5)

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
    }
}
