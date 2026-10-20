import SwiftUI

/// Pill chip showing a child's emoji avatar and name. Used in Home child rail and Gallery filter.
struct FWChildChip: View {
    let emoji: String
    let name: String
    var colorTint: Color = FW.Color.accent
    var isActive: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(FW.Font.caption(13))
                .foregroundStyle(FW.Color.onboardingInk)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(colorTint.opacity(isActive ? 0.78 : 0.48))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? FW.Color.primary.opacity(0.55) : Color.white.opacity(0.72),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// "All" chip variant for filter state.
struct FWAllChip: View {
    var isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("All")
                .font(FW.Font.caption(13))
                .foregroundStyle(FW.Color.onboardingInk)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Color(hex: 0xEAC8A9).opacity(isActive ? 0.82 : 0.52))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? FW.Color.primary.opacity(0.55) : Color.white.opacity(0.72),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
