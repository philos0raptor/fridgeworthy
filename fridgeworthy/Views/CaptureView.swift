import SwiftUI
import PhotosUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CaptureViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @Query(sort: \Child.createdAt) private var children: [Child]
    @State private var selectedChild: Child?

    let child: Child

    var activeChild: Child { selectedChild ?? child }

    var body: some View {
        NavigationStack {
            ZStack {
                FW.Color.bg.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Child picker (if multiple children)
                    if children.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(children) { c in
                                    FWChildChip(
                                        emoji: c.avatarEmoji,
                                        name: c.name,
                                        isActive: activeChild.id == c.id
                                    ) {
                                        selectedChild = c
                                    }
                                }
                            }
                            .padding(.horizontal, FW.Spacing.md)
                        }
                    }

                    if viewModel.showBeforeAfter {
                        beforeAfterPreview
                    } else if viewModel.isProcessing {
                        processingView
                    } else {
                        capturePrompt
                    }
                }

                // Upload overlay
                if viewModel.isUploading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Uploading...")
                            .foregroundStyle(.white)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .navigationTitle("Add Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FW.Color.accent)
                }
            }
            .disabled(viewModel.isUploading)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Upload Failed", isPresented: .constant(viewModel.uploadError != nil)) {
                Button("Retry") {
                    Task {
                        let success = await viewModel.saveArtwork(for: activeChild, context: modelContext)
                        if success { dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) { viewModel.uploadError = nil }
            } message: {
                Text(viewModel.uploadError ?? "")
            }
        }
    }

    private var capturePrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(FW.Color.accent.opacity(0.3))

            Text("Photograph \(activeChild.name)'s artwork")
                .font(FW.Font.sectionTitle())
                .multilineTextAlignment(.center)

            Text("We'll remove the background automatically")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Choose Photo")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(FW.Color.accent)
                .clipShape(Capsule())
                .shadow(color: FW.Color.accent.opacity(0.25), radius: 2, y: 1)
                .shadow(color: FW.Color.accent.opacity(0.3), radius: 10, y: 8)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.processImage(image)
                    }
                }
            }
            .padding(.horizontal, FW.Spacing.xl)

            Spacer()
        }
        .padding(.horizontal, FW.Spacing.md)
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(FW.Color.accent)
            Text("Removing background...")
                .font(FW.Font.body(15))
                .foregroundStyle(FW.Color.ink3)
        }
        .frame(maxHeight: .infinity)
    }

    private var beforeAfterPreview: some View {
        VStack(spacing: 20) {
            if let processed = viewModel.processedImage {
                Image(uiImage: processed)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 360)
                    .background {
                        RoundedRectangle(cornerRadius: FW.Radius.card, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [FW.Color.cream1, FW.Color.cream2],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: FW.Radius.card, style: .continuous))
                    .modifier(FW.Shadow.cardMedium())
                    .padding(.horizontal, FW.Spacing.md)
            }

            HStack(spacing: 16) {
                Button {
                    viewModel.reset()
                    selectedItem = nil
                } label: {
                    Text("Retake")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(FW.Color.ink)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5))
                }

                FWButton(title: "Save", icon: "checkmark") {
                    Task {
                        let success = await viewModel.saveArtwork(for: activeChild, context: modelContext)
                        if success { dismiss() }
                    }
                }
            }
            .padding(.horizontal, FW.Spacing.md)
        }
        .padding(.top, 20)
    }
}
