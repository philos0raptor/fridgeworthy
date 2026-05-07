import SwiftUI
import SwiftData

/// Main navigation container with floating tab bar.
struct MainTabView: View {
    @State private var selectedTab: FWTab = .home
    @State private var showCapture = false
    @Query private var children: [Child]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                case .gallery:
                    NavigationStack {
                        GalleryTabView()
                    }
                case .capture:
                    EmptyView()
                case .shop:
                    NavigationStack {
                        ShopPlaceholderView()
                    }
                case .me:
                    NavigationStack {
                        MeView()
                    }
                }
            }
            // Extra bottom padding so content doesn't hide behind tab bar
            .safeAreaPadding(.bottom, 80)

            FWTabBar(selectedTab: $selectedTab) {
                showCapture = true
            }
        }
        .sheet(isPresented: $showCapture) {
            if let firstChild = children.first {
                CaptureView(child: firstChild)
            }
        }
    }
}
