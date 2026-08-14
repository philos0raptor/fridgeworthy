import SwiftUI

/// Liquid glass surface effect (iOS 18 style).
/// Applies ultra-thin material with a subtle inner border.
struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassSurface(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius))
    }
}
