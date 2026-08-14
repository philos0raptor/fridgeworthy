import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Cream gradient background
            RadialGradient(
                colors: [FW.Color.cream1, FW.Color.cream2, FW.Color.cream3],
                center: .top,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()

            PaperTexture()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Brand mark
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(FW.Color.accent)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        }

                    Text("Fridgeworthy")
                        .font(FW.Font.sectionTitle(22))
                        .tracking(-0.5)
                }
                .padding(.top, 78)

                Spacer()

                // Stacked artwork cards
                artworkCardDeck
                    .frame(height: 270)

                Spacer().frame(height: 32)

                // Tagline
                VStack(spacing: 4) {
                    Text("Their art,")
                        .font(FW.Font.heroDisplay())
                        .tracking(-0.7)

                    ZStack(alignment: .bottom) {
                        Text("everywhere.")
                            .font(FW.Font.heroDisplay())
                            .tracking(-0.7)

                        FWCrayonUnderline(width: 180, height: 8)
                            .offset(y: 8)
                    }
                }

                Spacer().frame(height: 12)

                Text("Turn drawings into wallpapers,\nprints, and keepsakes.")
                    .font(FW.Font.body(16))
                    .foregroundStyle(FW.Color.ink2)
                    .multilineTextAlignment(.center)

                Spacer()

                // CTAs
                VStack(spacing: 12) {
                    // Apple Sign-In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 8)

                    // Email button
                    Button {
                        // TODO: email sign-in flow
                    } label: {
                        Text("Use email")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(FW.Color.ink)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 28)

                // Error
                if let error = errorMessage {
                    Text(error)
                        .font(FW.Font.caption())
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }

                // Footer
                HStack(spacing: 4) {
                    Text("By continuing you agree to our")
                        .font(FW.Font.caption(12))
                        .foregroundStyle(FW.Color.ink3)
                    Text("Terms")
                        .font(FW.Font.caption(12, weight: .medium))
                        .foregroundStyle(FW.Color.accent)
                    Text("&")
                        .font(FW.Font.caption(12))
                        .foregroundStyle(FW.Color.ink3)
                    Text("Privacy")
                        .font(FW.Font.caption(12, weight: .medium))
                        .foregroundStyle(FW.Color.accent)
                }
                .padding(.top, 16)
                .padding(.bottom, 44)
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Artwork Card Deck

    private var artworkCardDeck: some View {
        ZStack {
            // Bottom card
            placeholderCard(rotation: -7, offset: CGSize(width: -15, height: 8))
            // Middle card
            placeholderCard(rotation: 4, offset: CGSize(width: 12, height: 4))
            // Top card with tape
            ZStack(alignment: .top) {
                placeholderCard(rotation: -2, offset: .zero)

                // Yellow tape strip
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: 0xFFD966).opacity(0.85))
                    .frame(width: 48, height: 18)
                    .rotationEffect(.degrees(2))
                    .offset(y: -9)
            }
        }
    }

    private func placeholderCard(rotation: Double, offset: CGSize) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FW.Color.cream1, FW.Color.cream2],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 160, height: 180)
                .overlay {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(FW.Color.accent.opacity(0.3))
                }

            Text("By Maya, age 5")
                .font(FW.Font.caveat(14))
                .foregroundStyle(FW.Color.ink3)
        }
        .padding(10)
        .frame(width: 200, height: 240)
        .background(FW.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .rotationEffect(.degrees(rotation))
        .offset(offset)
    }

    // MARK: - Auth

    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            Task {
                do {
                    try await authService.signInWithApple(credential: credential)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
