import SwiftUI

/// Review is presented by the main Add Artwork flow before a photo enters the calendar.
struct ArtworkReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CaptureViewModel()

    let item: ArtworkReviewItem
    let onUse: (PendingArtworkPhoto) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isProcessing || !viewModel.showBeforeAfter {
                        ProgressView("Finding the paper…")
                            .frame(maxWidth: .infinity, minHeight: 340)
                    } else {
                        preview

                        if viewModel.detectionUncertain && !viewModel.hasChosenPreparation {
                            Text("We couldn't locate the paper with confidence. Move the corners onto it, or keep the full photo.")
                                .font(FW.Font.body(15))
                                .foregroundStyle(FW.Color.ink3)
                                .multilineTextAlignment(.center)
                        } else if !viewModel.isAdjustingCorners {
                            Text("Check that every mark is inside the crop.")
                                .font(FW.Font.body(15))
                                .foregroundStyle(FW.Color.ink3)
                        }

                        if viewModel.isAdjustingCorners {
                            Button("Use These Corners") { viewModel.prepareWithAdjustedCorners() }
                                .buttonStyle(.borderedProminent)
                            Button("Keep Full Photo") { viewModel.keepOriginal() }
                        } else {
                            HStack(spacing: 24) {
                                Button("Adjust Corners") { viewModel.isAdjustingCorners = true }
                                Button("Keep Full Photo") { viewModel.keepOriginal() }
                            }
                            .font(FW.Font.body(16))
                            .foregroundStyle(FW.Color.accent)
                        }

                        FWButton(title: "Use This Photo", icon: "checkmark") {
                            guard let preparedImage = viewModel.processedImage,
                                  viewModel.hasChosenPreparation else { return }
                            onUse(PendingArtworkPhoto(
                                preparedImage: preparedImage,
                                originalData: item.originalData
                            ))
                            dismiss()
                        }
                        .disabled(!viewModel.hasChosenPreparation || viewModel.isAdjustingCorners)
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .background(FW.Color.bg)
            .navigationTitle("Review Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn't prepare crop", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Please try again.")
            }
            .task {
                await viewModel.processImage(item.image, originalData: item.originalData)
            }
        }
    }

    private var preview: some View {
        Group {
            if viewModel.isAdjustingCorners,
               let image = viewModel.imageForCornerEditing,
               let corners = viewModel.paperCorners {
                PaperCornerEditor(image: image, corners: Binding(
                    get: { viewModel.paperCorners ?? corners },
                    set: { viewModel.paperCorners = $0 }
                ))
                .frame(height: 340)
            } else if let image = viewModel.processedImage ?? viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 340)
                    .accessibilityLabel("Prepared artwork preview")
            }
        }
        .frame(maxWidth: .infinity)
        .background(FW.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: FW.Radius.card, style: .continuous))
        .modifier(FW.Shadow.cardMedium())
    }
}
