#if DEBUG
import SwiftUI

/// Debug-only email/password sign-in.
///
/// Exists to get a *real* Supabase session in development without configuring Apple
/// Sign-In (Services ID, Team ID, .p8 key). Without a session `authService.currentUserID`
/// is nil, RLS rejects every write, and the upload path cannot be exercised at all.
///
/// This is deliberately unstyled — it is a development tool, not the production email
/// flow. The "Use email" CTA in `SignInView` still needs a designed sign-up experience.
struct DebugEmailSignInView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } footer: {
                    Text("Supabase requires at least 6 characters.")
                }

                Section {
                    Button("Sign in") {
                        run { try await authService.signInWithEmail(email: trimmedEmail, password: password) }
                    }
                    Button("Create account & sign in") {
                        run { try await authService.signUpWithEmail(email: trimmedEmail, password: password) }
                    }
                }
                .disabled(!isValid || isWorking)

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Debug sign-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if isWorking {
                    ToolbarItem(placement: .confirmationAction) { ProgressView() }
                }
            }
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        trimmedEmail.contains("@") && password.count >= 6
    }

    /// Runs an auth call, surfacing the error rather than swallowing it — the whole point
    /// of this screen is to see *why* a session could not be established.
    private func run(_ operation: @escaping () async throws -> Void) {
        isWorking = true
        errorMessage = nil

        Task {
            do {
                try await operation()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }
}
#endif
