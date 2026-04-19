import Foundation

public protocol AuthService: Sendable {
    var currentUserID: String? { get async }
    func signUp(email: String, password: String) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() async throws

    /// Sends both a magic link and a 6-digit OTP to the user's email in one Supabase call.
    /// The UI typically presents the OTP as the primary path; the link is a free fallback
    /// because Supabase includes both in the same email.
    func sendMagicLink(email: String) async throws

    /// Verifies a 6-digit OTP and returns the paired `UserProfile`. Used by the in-app
    /// code-entry flow after `sendMagicLink`.
    func verifyEmailOTP(email: String, token: String) async throws -> UserProfile

    /// Signs in with Apple via Supabase `signInWithIdToken`. The `idToken` and `nonce`
    /// come from `ASAuthorizationAppleIDCredential`. Supabase verifies the token against
    /// Apple's JWKS and creates/finds the user.
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile

    /// Signs in with Google via Supabase `signInWithIdToken`. The `idToken` and
    /// `accessToken` come from `GIDSignInResult`. Supabase verifies the token against
    /// Google's JWKS and creates/finds the user.
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile

    /// Flips `user_profiles.onboarding_completed` to `true`. Called when the onboarding
    /// wizard finishes successfully, after the `HealthProfile` has been saved.
    func completeOnboarding(userID: String) async throws

    /// Debug-only: updates a user's subscription tier directly.
    func updateTier(userID: String, tier: SubscriptionTier) async throws
}
