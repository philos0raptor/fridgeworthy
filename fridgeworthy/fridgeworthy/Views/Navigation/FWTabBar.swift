import SwiftUI

enum FWTab: Int, CaseIterable {
    case home, gallery, capture, shop, me

    var label: String {
        switch self {
        case .home: "Home"
        case .gallery: "Gallery"
        case .capture: ""
        case .shop: "Shop"
        case .me: "Account"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .gallery: "photo.on.rectangle"
        case .capture: "plus"
        case .shop: "bag"
        case .me: "person"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: "house.fill"
        case .gallery: "photo.on.rectangle.fill"
        case .capture: "plus"
        case .shop: "bag.fill"
        case .me: "person.fill"
        }
    }
}

/// Floating pill tab bar matching the Fridgeworthy design spec.
/// 64pt tall, 16pt margin from edges, 18pt from bottom.
struct FWTabBar: View {
    @Binding var selectedTab: FWTab
    var onCaptureTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FWTab.allCases, id: \.self) { tab in
                if tab == .capture {
                    captureButton
                } else {
                    tabButton(tab)
                }
            }
        }
        .frame(height: 64)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.10), radius: 12, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    private func tabButton(_ tab: FWTab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.1)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.monochrome)

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? FW.Color.accent : FW.Color.ink3)
            .frame(maxWidth: .infinity)
            .scaleEffect(selectedTab == tab ? 1 : 0.95)
        }
        .buttonStyle(.plain)
    }

    private var captureButton: some View {
        Button(action: onCaptureTap) {
            ZStack {
                Circle()
                    .fill(FW.Color.accent)
                    .frame(width: 48, height: 48)
                    .shadow(color: FW.Color.accent.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
