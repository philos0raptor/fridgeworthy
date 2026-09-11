import Foundation
import RevenueCat
import Observation

/// Manages subscription state via RevenueCat.
@Observable
final class RevenueCatService {
    enum PurchaseError: LocalizedError {
        case notConfigured

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Purchases aren't available right now."
            }
        }
    }

    var isProUser = false

    func checkSubscriptionStatus() async {
        guard Purchases.isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isProUser = customerInfo.entitlements["pro"]?.isActive == true
        } catch {
            isProUser = false
        }
    }

    func fetchOfferings() async -> [Package] {
        guard Purchases.isConfigured else { return [] }
        do {
            let offerings = try await Purchases.shared.offerings()
            return offerings.current?.availablePackages ?? []
        } catch {
            return []
        }
    }

    func purchase(package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        let isPro = result.customerInfo.entitlements["pro"]?.isActive == true
        isProUser = isPro
        return isPro
    }

    func restorePurchases() async throws {
        guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
        let customerInfo = try await Purchases.shared.restorePurchases()
        isProUser = customerInfo.entitlements["pro"]?.isActive == true
    }
}
