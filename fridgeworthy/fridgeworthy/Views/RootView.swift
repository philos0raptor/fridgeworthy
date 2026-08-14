import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(RevenueCatService.self) private var revenueCatService
    @Environment(\.modelContext) private var modelContext

    // DEBUG-only local bypass. Never compiled into Release builds.
    #if DEBUG
    private let debugSkipAuth = true
    #else
    private let debugSkipAuth = false
    #endif

    var body: some View {
        Group {
            if debugSkipAuth || authService.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .task {
            await authService.restoreSession()
            if authService.isAuthenticated, let userID = authService.currentUserID {
                ensureLocalProfile(userID: userID)
                await revenueCatService.checkSubscriptionStatus()
            }
        }
        .onAppear {
            if debugSkipAuth {
                SeedDataService.seedIfNeeded(modelContext: modelContext)
            }
        }
    }

    private func ensureLocalProfile(userID: UUID) {
        let userIDString = userID.uuidString
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.supabaseID == userIDString }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if existing.isEmpty {
            let profile = UserProfile(supabaseID: userIDString)
            modelContext.insert(profile)
        }
    }
}
