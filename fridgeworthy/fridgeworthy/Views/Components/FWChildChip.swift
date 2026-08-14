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
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 16))
                    .frame(width: 28, height: 28)
                    .background(colorTint.opacity(0.15))
                    .clipShape(Circle())

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isActive ? FW.Color.accent : FW.Color.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(FW.Color.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? FW.Color.accent : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .modifier(FW.Shadow.cardSoft())
        }
        .buttonStyle(.plain)
    }
}

/// "All" chip variant for filter state.
struct FWAllChip: View {
    var isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13, weight: .semibold))
                Text("All")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(isActive ? FW.Color.accent : FW.Color.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(FW.Color.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? FW.Color.accent : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .modifier(FW.Shadow.cardSoft())
        }
        .buttonStyle(.plain)
    }
}
