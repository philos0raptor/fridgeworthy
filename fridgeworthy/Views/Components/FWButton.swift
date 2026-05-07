import SwiftUI

/// Fridgeworthy branded button with primary (purple pill) and secondary (glass) variants.
struct FWButton: View {
    enum Style {
        case primary
        case primaryDark
        case secondary
    }

    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(foregroundColor)
            .background(background)
            .clipShape(Capsule())
            .overlay {
                if style == .secondary {
                    Capsule()
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                }
            }
            .shadow(
                color: shadowColor1, radius: shadowRadius1,
                x: 0, y: shadowY1
            )
            .shadow(
                color: shadowColor2, radius: shadowRadius2,
                x: 0, y: shadowY2
            )
            .opacity(isDisabled ? 0.4 : 1)
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.05), value: isPressed)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: .white
        case .primaryDark: .white
        case .secondary: FW.Color.ink
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            FW.Color.accent
        case .primaryDark:
            Color.black
        case .secondary:
            Color.white.opacity(0.78)
                .background(.ultraThinMaterial)
        }
    }

    // Shadow properties broken out to avoid opaque return type mismatch
    private var shadowColor1: Color {
        switch style {
        case .primary: FW.Color.accent.opacity(0.25)
        case .primaryDark: Color.black.opacity(0.18)
        case .secondary: Color.black.opacity(0.04)
        }
    }
    private var shadowRadius1: CGFloat {
        switch style {
        case .primary, .primaryDark: 2
        case .secondary: 1
        }
    }
    private var shadowY1: CGFloat { 1 }

    private var shadowColor2: Color {
        switch style {
        case .primary: FW.Color.accent.opacity(0.3)
        case .primaryDark: Color.black.opacity(0.18)
        case .secondary: Color.black.opacity(0.04)
        }
    }
    private var shadowRadius2: CGFloat {
        switch style {
        case .primary, .primaryDark: 10
        case .secondary: 6
        }
    }
    private var shadowY2: CGFloat { 8 }
}
