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

        // Upsert profile with name from Apple credential
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        try await adopt(
            session,
            email: credential.email ?? session.user.email,
            displayName: fullName.isEmpty ? nil : fullName
        )
    }

    /// Email/password sign-in. Backs the debug sign-in sheet today; the "Use email"
    /// CTA in `SignInView` is the eventual production caller.
    func signInWithEmail(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        try await adopt(session, email: session.user.email, displayName: nil)
    }

    /// Creates an account, then signs in to obtain a session.
    ///
    /// Signing in as a separate step rather than reading the sign-up response keeps this
    /// correct whether or not the project auto-confirms email: with confirmation required,
    /// sign-up returns a user but no session, and this surfaces that as a sign-in failure
    /// instead of silently leaving `currentUserID` nil.
    func signUpWithEmail(email: String, password: String) async throws {
        _ = try await supabase.auth.signUp(email: email, password: password)
        try await signInWithEmail(email: email, password: password)
    }

    /// Shared post-authentication work for every sign-in path.
    private func adopt(_ session: Session, email: String?, displayName: String?) async throws {
        currentUserID = session.user.id
        isAuthenticated = true

        try await SupabaseService.shared.upsertProfile(
            id: session.user.id,
            email: email,
            displayName: displayName
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
