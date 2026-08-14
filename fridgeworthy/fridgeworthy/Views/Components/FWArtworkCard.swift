import SwiftUI

/// White card framing artwork in a "drawing on paper" style.
struct FWArtworkCard: View {
    var image: UIImage? = nil
    var remoteURL: String? = nil
    var caption: String? = nil
    var innerPadding: CGFloat = 8
    var cornerRadius: CGFloat = FW.Radius.card

    var body: some View {
        VStack(spacing: 0) {
            artworkContent
                .padding(innerPadding)

            if let caption {
                Text(caption)
                    .font(FW.Font.caveat(16))
                    .foregroundStyle(FW.Color.ink3)
                    .padding(.bottom, 8)
            }
        }
        .background(FW.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .modifier(FW.Shadow.cardSoft())
    }

    @ViewBuilder
    private var artworkContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .background(
                    LinearGradient(
                        colors: [FW.Color.cream1, FW.Color.cream2],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous))
        } else if let remoteURL, let url = URL(string: remoteURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit()
                case .failure:
                    placeholder
                default:
                    ProgressView()
                        .frame(minHeight: 120)
                }
            }
            .background(
                LinearGradient(
                    colors: [FW.Color.cream1, FW.Color.cream2],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous)
            .fill(FW.Color.cream1)
            .frame(minHeight: 120)
            .overlay {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundStyle(FW.Color.ink4)
            }
    }
}

/// Glass caption pill overlay for artwork cards (e.g., "Maya, age 5").
struct FWGlassCaptionPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FW.Font.caveat(15))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassSurface(cornerRadius: 16)
    }
}
