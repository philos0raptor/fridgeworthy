import Foundation

enum AppConfig {
    // These values come from the xcconfig files via build settings.
    // They're injected as preprocessor macros in the target build settings.
    //
    // To configure: edit Config/Debug.xcconfig (or Release.xcconfig) with your values,
    // then clean build (Cmd+Shift+K) and rebuild.

    static let supabaseURL: URL = {
        // Read from xcconfig via build setting -> Info.plist isn't available,
        // so we use a Secrets.swift file instead (gitignored).
        guard let url = URL(string: Secrets.supabaseURL) else {
            fatalError("Invalid SUPABASE_URL")
        }
        return url
    }()

    static let supabaseAnonKey: String = Secrets.supabaseAnonKey

    static let revenueCatAPIKey: String? = {
        let key = Secrets.revenueCatAPIKey
        return key == "YOUR_REVENUECAT_API_KEY" ? nil : key
    }()
}
