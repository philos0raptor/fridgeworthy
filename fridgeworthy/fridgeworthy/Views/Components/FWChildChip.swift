import SwiftUI

/// A child choice that grows to reveal its checkmark when selected.
struct FWAnimatedSelectionChip: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let name: String
    let colorTint: Color
    let isActive: Bool
    let onTap: () -> Void

    var font: Font = FW.Font.caption(13)
    var horizontalPadding: CGFloat = 13
    var verticalPadding: CGFloat = 8
    var fillsWidth = false
    var activeFillOpacity = 0.78
    var inactiveFillOpacity = 0.48
    var activeBorderColor: Color = FW.Color.primary.opacity(0.55)

    private let selectionAnimation = Animation.spring(response: 0.32, dampingFraction: 0.82)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 7) {
                Text(name)
                    .font(font)
                    .foregroundStyle(FW.Color.onboardingInk.opacity(isActive ? 1 : 0.78))
                    .lineLimit(1)

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FW.Color.onboardingInk)
                        .accessibilityHidden(true)
                        .transition(.opacity.combined(with: .scale(scale: 0.65)))
                }
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.leading, horizontalPadding)
            .padding(.trailing, isActive ? horizontalPadding - 3 : horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(colorTint.opacity(isActive ? activeFillOpacity : inactiveFillOpacity))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isActive ? activeBorderColor : Color.white.opacity(0.72),
                        lineWidth: isActive ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : selectionAnimation, value: isActive)
        .accessibilityLabel(name)
        .accessibilityValue(isActive ? "Selected" : "Not selected")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// Animates neighboring choices as the selected chip changes width.
struct FWSelectionLayoutAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let selection: UUID?

    func body(content: Content) -> some View {
        content.animation(
            reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.82),
            value: selection
        )
    }
}

struct FWChildChip: View {
    let emoji: String
    let name: String
    var colorTint: Color = FW.Color.accent
    var isActive: Bool = false
    let onTap: () -> Void

    var body: some View {
        FWAnimatedSelectionChip(
            name: name,
            colorTint: colorTint,
            isActive: isActive,
            onTap: onTap
        )
    }
}

struct FWAllChip: View {
    var isActive: Bool
    let onTap: () -> Void

    var body: some View {
        FWAnimatedSelectionChip(
            name: "All",
            colorTint: Color(hex: 0xEAC8A9),
            isActive: isActive,
            onTap: onTap,
            activeFillOpacity: 0.82,
            inactiveFillOpacity: 0.52
        )
    }
}
