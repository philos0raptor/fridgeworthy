import SwiftUI

struct ShopPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag")
                .font(.system(size: 48))
                .foregroundStyle(FW.Color.ink4)

            Text("Shop")
                .font(FW.Font.sectionTitle())
                .foregroundStyle(FW.Color.ink)

            Text("Prints, gifts & more — coming soon.")
                .font(FW.Font.body())
                .foregroundStyle(FW.Color.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FW.Color.bg)
    }
}
