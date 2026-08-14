import SwiftUI
import SwiftData
import RevenueCat

@main
struct FridgeworthyApp: App {
    @State private var authService = AuthService()
    @State private var revenueCatService = RevenueCatService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Child.self,
            Artwork.self,
            StyleTemplate.self,
            Wallpaper.self,
            GenerationJob.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(revenueCatService)
                .task {
                    await revenueCatService.checkSubscriptionStatus()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    init() {
        FW.registerFonts()

        // RevenueCat — only configure if key is provided
        if let rcKey = AppConfig.revenueCatAPIKey {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: rcKey)
        }

        // Supabase client initializes lazily via SupabaseService.shared
        _ = SupabaseService.shared
    }
}
