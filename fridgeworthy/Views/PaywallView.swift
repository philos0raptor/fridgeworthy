import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RevenueCatService.self) private var revenueCatService
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    enum Plan { case monthly, yearly }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Purple gradient background
            RadialGradient(
                colors: [FW.Color.paywall1, FW.Color.paywall2, FW.Color.paywall3],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            PaperTexture(opacity: 0.25)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero fan cards
                    heroCards
                        .padding(.top, 60)

                    // White sheet
                    VStack(spacing: 20) {
                        // Headline
                        VStack(spacing: 8) {
                            (Text("Unlock the\n") + Text("full studio."))
                                .font(.system(size: 30, weight: .heavy))
                                .tracking(-0.7)
                                .multilineTextAlignment(.center)

                            Text("Every style. Unlimited wallpapers. Free shipping.")
                                .font(FW.Font.body(15))
                                .foregroundStyle(FW.Color.ink3)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 28)

                        // Feature rows
                        VStack(spacing: 14) {
                            featureRow("All wallpaper styles unlocked")
                            featureRow("Unlimited generations per month")
                            featureRow("Free prints shipping worldwide")
                        }
                        .padding(.horizontal, FW.Spacing.lg)

                        // Plan cards
                        VStack(spacing: 12) {
                            planCard(
                                plan: .monthly,
                                title: "Monthly",
                                price: "$4.99",
                                period: "/mo"
                            )
                            planCard(
                                plan: .yearly,
                                title: "Yearly",
                                price: "$39.99",
                                period: "/yr",
                                badge: "SAVE 33%"
                            )
                        }
                        .padding(.horizontal, FW.Spacing.md)

                        // CTA
                        FWButton(title: isPurchasing ? "Starting…" : "Start 7-day free trial") {
                            Task { await startPurchase() }
                        }
                        .disabled(isPurchasing)
                        .padding(.horizontal, FW.Spacing.md)

                        if let purchaseError {
                            Text(purchaseError)
                                .font(FW.Font.caption(13))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FW.Spacing.md)
                        }

                        // Footer
                        HStack(spacing: 4) {
                            Text("Cancel anytime")
                                .foregroundStyle(FW.Color.ink3)
                            Text("·")
                                .foregroundStyle(FW.Color.ink4)
                            Button("Restore purchases") {
                                Task {
                                    try? await revenueCatService.restorePurchases()
                                    if revenueCatService.isProUser { dismiss() }
                                }
                            }
                            .foregroundStyle(FW.Color.accent)
                        }
                        .font(FW.Font.caption(13))
                        .padding(.bottom, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .background(FW.Color.card)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: FW.Radius.sheetLg,
                            topTrailingRadius: FW.Radius.sheetLg
                        )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 16, y: -8)
                }
            }

            // Close button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .glassSurface(cornerRadius: 16)
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
    }

    // MARK: - Hero Fan Cards

    private var heroCards: some View {
        ZStack {
            // Left card
            previewCard
                .rotationEffect(.degrees(-8))
                .offset(x: -50, y: 10)

            // Right card
            previewCard
                .rotationEffect(.degrees(8))
                .offset(x: 50, y: 10)

            // Center card (on top)
            ZStack(alignment: .top) {
                previewCard

                // Crown badge
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: 0xFFD966))
                    .offset(y: -16)
            }
        }
        .frame(height: 260)
        .padding(.bottom, 16)
    }

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: FW.Radius.cardLg, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [FW.Color.cream1, FW.Color.accent.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 150, height: 240)
            .overlay {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(FW.Color.accent.opacity(0.25))
            }
            .modifier(FW.Shadow.cardMedium())
    }

    // MARK: - Feature Row

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(FW.Color.accent)
                .clipShape(Circle())

            Text(text)
                .font(FW.Font.body(15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Plan Card

    private func planCard(plan: Plan, title: String, price: String, period: String, badge: String? = nil) -> some View {
        let isSelected = selectedPlan == plan

        return Button { selectedPlan = plan } label: {
            ZStack(alignment: .top) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(price)
                                .font(.system(size: 22, weight: .bold))
                            Text(period)
                                .font(FW.Font.caption(14))
                                .foregroundStyle(FW.Color.ink3)
                        }
                    }
                    Spacer()
                    Circle()
                        .strokeBorder(isSelected ? FW.Color.accent : FW.Color.ink4, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .fill(FW.Color.accent)
                                    .frame(width: 14, height: 14)
                            }
                        }
                }
                .padding(FW.Spacing.md)
                .background(isSelected ? FW.Color.accent.opacity(0.06) : FW.Color.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? FW.Color.accent : .clear, lineWidth: 2)
                )

                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(FW.Color.accent)
                        .clipShape(Capsule())
                        .offset(y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase

    private func startPurchase() async {
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }

        let packages = await revenueCatService.fetchOfferings()
        let desired: PackageType = selectedPlan == .monthly ? .monthly : .annual
        guard let package = packages.first(where: { $0.packageType == desired }) else {
            purchaseError = "That plan isn't available right now. Please try again."
            return
        }

        do {
            let success = try await revenueCatService.purchase(package: package)
            if success { dismiss() }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
