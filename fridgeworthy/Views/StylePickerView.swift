import SwiftUI
import SwiftData

struct StylePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(RevenueCatService.self) private var revenueCatService
    @Query(sort: \StyleTemplate.sortOrder) private var styles: [StyleTemplate]
    @State private var selectedStyle: StyleTemplate?
    @State private var showPaywall = false

    let child: Child
    let onStyleSelected: (StyleTemplate) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Lock-screen preview
                lockScreenPreview
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // Style name
                if let style = selectedStyle {
                    VStack(spacing: 4) {
                        Text(style.name)
                            .font(FW.Font.sectionTitle())
                            .tracking(-0.5)
                        Text(style.styleDescription)
                            .font(FW.Font.caption(14))
                            .foregroundStyle(FW.Color.ink3)
                    }
                    .padding(.bottom, 16)
                }

                // Style grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(styles) { style in
                            styleThumbnail(style)
                        }
                    }
                    .padding(.horizontal, FW.Spacing.md)
                }

                Spacer()

                // Bottom CTA
                FWButton(title: "Generate · 3 free left", icon: "wand.and.stars") {
                    if let style = selectedStyle {
                        onStyleSelected(style)
                    }
                }
                .padding(.horizontal, FW.Spacing.md)
                .padding(.bottom, 24)
            }
            .background(FW.Color.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundStyle(FW.Color.accent)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Choose style")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            await StyleTemplateSyncService.sync(context: modelContext)
            if selectedStyle == nil {
                selectedStyle = styles.first
            }
        }
    }

    // MARK: - Lock Screen Preview

    private var lockScreenPreview: some View {
        ZStack {
            // Phone frame
            RoundedRectangle(cornerRadius: FW.Radius.deviceOuter, style: .continuous)
                .fill(Color.black)
                .frame(width: 180, height: 300)
                .overlay {
                    // Screen
                    RoundedRectangle(cornerRadius: FW.Radius.deviceScreen, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [FW.Color.cream1, FW.Color.accent.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(4)
                        .overlay {
                            // Lock screen content
                            VStack(spacing: 2) {
                                // Dynamic Island
                                Capsule()
                                    .fill(.black)
                                    .frame(width: 70, height: 22)
                                    .padding(.top, 12)

                                Spacer().frame(height: 20)

                                Text("Tuesday, Oct 28")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))

                                Text("9:41")
                                    .font(.system(size: 42, weight: .ultraLight))
                                    .foregroundStyle(.white)

                                Spacer()
                            }
                        }
                }
                .modifier(FW.Shadow.cardHero())
        }
    }

    // MARK: - Style Thumbnail

    private func styleThumbnail(_ style: StyleTemplate) -> some View {
        let isSelected = selectedStyle?.id == style.id
        let isLocked = style.tier == .pro && !revenueCatService.isProUser

        return Button {
            if isLocked {
                showPaywall = true
            } else {
                withAnimation(.easeOut(duration: 0.18)) {
                    selectedStyle = style
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                // Preview image
                Group {
                    if let url = style.previewImageURL, let imgURL = URL(string: url) {
                        AsyncImage(url: imgURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(FW.Color.surface2)
                        }
                    } else {
                        Rectangle().fill(FW.Color.surface2)
                            .overlay {
                                Image(systemName: "paintbrush")
                                    .foregroundStyle(FW.Color.ink4)
                            }
                    }
                }
                .aspectRatio(1/1.2, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnail, style: .continuous))

                // Caption gradient
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FW.Radius.thumbnail, style: .continuous))
                    .overlay(alignment: .bottom) {
                        Text(style.name)
                            .font(FW.Font.caption(11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 6)
                    }
                }

                // PRO pill
                if isLocked {
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(FW.Color.accent)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: FW.Radius.thumbnail, style: .continuous)
                    .strokeBorder(isSelected ? FW.Color.accent : .clear, lineWidth: 2.5)
            )
            .shadow(
                color: isSelected ? FW.Color.accent.opacity(0.25) : .clear,
                radius: isSelected ? 6 : 0,
                y: isSelected ? 3 : 0
            )
        }
        .buttonStyle(.plain)
    }
}
