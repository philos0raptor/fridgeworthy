import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Main navigation container with floating tab bar.
struct MainTabView: View {
    @State private var selectedTab: FWTab = .home
    @State private var showActionSheet = false
    @State private var showCamera = false
    @State private var showCaptureWithImage = false
    @State private var capturedImage: UIImage?
    @State private var libraryItem: PhotosPickerItem?
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
                        HomeView()
                    }
                case .gallery:
                    NavigationStack {
                        GalleryTabView()
                    }
                case .capture:
                    EmptyView()
                case .shop:
                    NavigationStack {
                        ShopPlaceholderView()
                    }
                case .me:
                    NavigationStack {
                        MeView()
                    }
                }
            }
            // Extra bottom padding so content doesn't hide behind tab bar
            .safeAreaPadding(.bottom, 80)

            FWTabBar(selectedTab: $selectedTab) {
                showActionSheet = true
            }
        }
        .confirmationDialog("Add Artwork", isPresented: $showActionSheet, titleVisibility: .visible) {
            if cameraAvailable {
                Button("Take Photo") {
                    showCamera = true
                }
            }
            Button("Choose from Library") {
                libraryItem = nil
                showLibraryPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $libraryItem, matching: .images)
        .onChange(of: libraryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                    showCaptureWithImage = true
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if capturedImage != nil {
                showCaptureWithImage = true
            }
        }) {
            CameraView { image in
                capturedImage = image
            }
        }
        .sheet(isPresented: $showCaptureWithImage, onDismiss: {
            capturedImage = nil
        }) {
            if let firstChild = children.first, let image = capturedImage {
                CaptureView(child: firstChild, initialImage: image)
            }
        }
    }

    @State private var showLibraryPicker = false
}
