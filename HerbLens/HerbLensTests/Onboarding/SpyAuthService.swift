import Foundation
@testable import HerbLens

/// Instrumentable `AuthService` mock. Actor so recorded calls are thread-safe
/// across `Task`-driven state transitions.
actor SpyAuthService: AuthService {
    struct Calls {
        var sendMagicLink: [String] = []
        var verifyEmailOTP: [(email: String, token: String)] = []
        var completeOnboarding: [String] = []
    }

    enum Failure: Error, Equatable {
        case magicLinkFailed
        case verifyFailed
        case completeFailed
    }

    private(set) var calls = Calls()

    private var fixedUserID: String?
    private let profileResult: UserProfile
    private var failMagicLink = false
    private var failVerify = false
    private var failComplete = false

    init(
        profile: UserProfile = SampleData.userProfile,
        currentUserID: String? = nil
    ) {
        self.profileResult = profile
        self.fixedUserID = currentUserID
    }

    // MARK: - Failure injection

    func setFailMagicLink(_ value: Bool) { failMagicLink = value }
    func setFailVerify(_ value: Bool) { failVerify = value }
    func setFailComplete(_ value: Bool) { failComplete = value }
    func setCurrentUserID(_ value: String?) { fixedUserID = value }

    // MARK: - AuthService

    var currentUserID: String? { fixedUserID }

    func signUp(email: String, password: String) async throws -> UserProfile { profileResult }
    func signIn(email: String, password: String) async throws -> UserProfile { profileResult }
    func signOut() async throws {}

    func sendMagicLink(email: String) async throws {
        calls.sendMagicLink.append(email)
        if failMagicLink { throw Failure.magicLinkFailed }
    }

    func verifyEmailOTP(email: String, token: String) async throws -> UserProfile {
        calls.verifyEmailOTP.append((email, token))
        if failVerify { throw Failure.verifyFailed }
        // Pretend session got established after successful verify.
        fixedUserID = profileResult.id
        return profileResult
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        fixedUserID = profileResult.id
        return profileResult
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile {
        fixedUserID = profileResult.id
        return profileResult
    }

    func completeOnboarding(userID: String) async throws {
        calls.completeOnboarding.append(userID)
        if failComplete { throw Failure.completeFailed }
    }
}

/// Instrumentable `HealthProfileRepository` mock.
actor SpyHealthProfileRepository: HealthProfileRepository {
    private(set) var savedProfiles: [HealthProfile] = []
    private var failSave = false

    func setFailSave(_ value: Bool) { failSave = value }

    func load(userID: String) async throws -> HealthProfile {
        savedProfiles.last ?? HealthProfile(goals: [], experienceLevel: .beginner)
    }

    func save(_ profile: HealthProfile) async throws {
        if failSave { throw NSError(domain: "test", code: 1) }
        savedProfiles.append(profile)
    }
}

/// Minimal `SubscriptionService` returning a configured tier.
actor StubSubscriptionService: SubscriptionService {
    private var tier: SubscriptionTier

    init(tier: SubscriptionTier = .free) { self.tier = tier }

    func currentTier() async -> SubscriptionTier { tier }
    func offerings() async throws -> [Offering] { [] }
    func purchase(packageID: String) async throws -> SubscriptionTier { tier }
    func restore() async throws -> SubscriptionTier { tier }
}
