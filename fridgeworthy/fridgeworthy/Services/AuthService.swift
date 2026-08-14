import Foundation
import AuthenticationServices
import Supabase
import Observation

/// Handles Apple Sign-In → Supabase Auth session management.
@Observable
final class AuthService {
    var isAuthenticated = false
    var currentUserID: UUID?

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidToken
        }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        currentUserID = session.user.id
        isAuthenticated = true

        // Upsert profile with name from Apple credential
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        try await SupabaseService.shared.upsertProfile(
            id: session.user.id,
            email: credential.email ?? session.user.email,
            displayName: fullName.isEmpty ? nil : fullName
        )
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
        currentUserID = nil
    }

    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserID = session.user.id
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUserID = nil
        }
    }
}

enum AuthError: LocalizedError {
    case invalidToken
    case signInFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid authentication token"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        }
    }
}
