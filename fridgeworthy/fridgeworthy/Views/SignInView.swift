import AuthenticationServices
import SwiftUI

struct SignInView: View {
    private enum AuthEntryMode {
        case newParent
        case returningParent
    }

    @Environment(AuthService.self) private var authService
    @State private var entryMode: AuthEntryMode = .newParent
    @State private var errorMessage: String?

    #if DEBUG
    @State private var showDebugEmailSignIn = false
    #endif

    var body: some View {
        ZStack {
            FWPaperBackground(topTint: entryMode == .newParent ? FW.Color.lavender : FW.Color.sky)

            VStack(spacing: 0) {
                FWHandwrittenStatusBar(inkColor: FW.Color.onboardingInk)

                Spacer().frame(height: 12)

                fridgeIllustration

                Spacer().frame(height: 18)

                message

                Spacer(minLength: 30)

                authenticationActions
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .foregroundStyle(FW.Color.onboardingInk)
        }
        .statusBarHidden(true)
        .animation(.easeInOut(duration: 0.28), value: entryMode)
        #if DEBUG
        .sheet(isPresented: $showDebugEmailSignIn) {
            DebugEmailSignInView()
        }
        #endif
    }

    private var fridgeIllustration: some View {
        Image("FWFridge")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(FW.Color.onboardingInk)
            .scaleEffect(1.55)
            .frame(width: 90, height: 90)
            .clipped()
            .frame(height: 108)
        #if DEBUG
        .onLongPressGesture(minimumDuration: 1.5) {
            showDebugEmailSignIn = true
        }
        #endif
    }

    @ViewBuilder
    private var message: some View {
        VStack(spacing: 14) {
            if entryMode == .newParent {
                Text("Hi parents")
                    .font(FW.Font.caption(16))
                    .tracking(-0.6)
                    .multilineTextAlignment(.center)

                Text("I created Fridgeworthy as a home for the\n art,stories and proud moments\nyour kids bring home")
                    .font(FW.Font.body(16))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text("I hope every time you\nlook at this app you’re\nreminded of")
                    .font(FW.Font.body(16))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text("That sepcial moment")
                    .font(FW.Font.body(16))

                Image("FWPhil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(FW.Color.onboardingInk)
                    .frame(width: 114, height: 100)
                    .accessibilityLabel("Phil")

                Text("Emma and Kaia's dad")
                    .font(FW.Font.body(9))

            } else {
                Text("Welcome back.")
                    .font(FW.Font.heroDisplay(32))
                    .tracking(-0.8)

                Text("Your family’s little masterpieces are right where you left them.")
                    .font(FW.Font.body(16))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 300)

                Text("Continue with Apple to open your fridge.")
                    .font(FW.Font.keepsake(15))
                    .italic()
                    .foregroundStyle(FW.Color.onboardingInk)
            }
        }
    }

    private var authenticationActions: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .font(FW.Font.caption(12))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            HStack(spacing: 4) {
                Text("By continuing, you agree to our")
                Button("Terms") {}
                    .underline()
                    .accessibilityHint("Legal destination will be added before release")
                Text("and")
                Button("Privacy Policy") {}
                    .underline()
                    .accessibilityHint("Legal destination will be added before release")
            }
            .font(FW.Font.caption(10))
            .foregroundStyle(FW.Color.onboardingInk)

            appleAction
            .frame(height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: FW.Color.ink.opacity(0.16), radius: 12, y: 8)

            Button {
                errorMessage = nil
                entryMode = entryMode == .newParent ? .returningParent : .newParent
            } label: {
                HStack(spacing: 3) {
                    Text(entryMode == .newParent ? "Already have an account?" : "New to Fridgeworthy?")
                    Text(entryMode == .newParent ? "Sign in" : "Create an account")
                        .foregroundStyle(FW.Color.onboardingInk)
                }
                .font(FW.Font.caption(13))
                .foregroundStyle(FW.Color.onboardingInk)
            }
            .buttonStyle(.plain)

            Capsule()
                .fill(FW.Color.ink)
                .frame(width: 126, height: 5)
                .padding(.top, 3)
        }
    }

    @ViewBuilder
    private var appleAction: some View {
        #if DEBUG
        Button {
            errorMessage = nil
            authService.continueWithoutAuthentication()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 24, weight: .medium))
                Text("Continue with Apple")
                    .font(.system(size: 23, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue with Apple")
        .accessibilityHint("Prototype only: opens the main app without signing in")
        #else
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            handleAppleSignIn(result)
        }
        .signInWithAppleButtonStyle(.black)
        #endif
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }
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
