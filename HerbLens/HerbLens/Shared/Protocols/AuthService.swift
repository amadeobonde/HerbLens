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

    /// Flips `user_profiles.onboarding_completed` to `true`. Called when the onboarding
    /// wizard finishes successfully, after the `HealthProfile` has been saved.
    func completeOnboarding(userID: String) async throws
}
