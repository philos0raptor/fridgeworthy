import SwiftUI

enum FWTab: Int, CaseIterable {
    case home, capture, settings

    var label: String {
        switch self {
        case .home: "Month overview"
        case .capture: "Add memory"
        case .settings: "Settings"
        }
    }

    var doodleAsset: String {
        switch self {
        case .home: "FWNavHome"
        case .capture: "FWNavCapture"
        case .settings: "FWNavAccount"
        }
    }
}

struct FWTabBar: View {
    @Binding var selectedTab: FWTab
    var onCaptureTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FWTab.allCases, id: \.self) { tab in
                Button {
                    if tab == .capture {
                        onCaptureTap()
                    } else {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    doodle(for: tab)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .frame(width: 256, height: 66)
        .padding(.horizontal, 7)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: FW.Color.primary.opacity(0.12), radius: 18, y: 10)
        .padding(.horizontal, 30)
        .padding(.bottom, 12)
    }

    private func doodle(for tab: FWTab) -> some View {
        ZStack {
            Circle()
                .fill(selectedTab == tab ? FW.Color.lavender : .clear)
                .frame(width: 50, height: 50)

            Image(tab.doodleAsset)
                .resizable()
                .scaledToFit()
                .scaleEffect(tab == .capture ? 1.9 : 1.65)
                .frame(width: 34, height: 34)
                .clipped()
        }
        .frame(width: 54, height: 54)
        .scaleEffect(selectedTab == tab ? 1 : 0.94)
    }
}
