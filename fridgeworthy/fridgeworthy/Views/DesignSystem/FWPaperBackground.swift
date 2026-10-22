import SwiftUI

struct FWPaperBackground: View {
    var topTint: Color = FW.Color.lavender

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: topTint, location: 0),
                .init(color: FW.Color.sky.opacity(0.72), location: 0.16),
                .init(color: FW.Color.paper.opacity(0.97), location: 0.42),
                .init(color: FW.Color.paper, location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            PaperTexture()
                .opacity(0.28)
        }
        .ignoresSafeArea()
    }
}
