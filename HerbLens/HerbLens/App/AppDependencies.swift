import Foundation

/// Dependency-injection container passed down through the SwiftUI `@Environment`.
/// Each feature view reads the service it needs via `@Environment(\.dependencies)` rather
/// than constructing services directly — lets us swap Live ↔ Mock in previews and tests.
public nonisolated struct AppDependencies: Sendable {
    public let auth: any AuthService
    public let plants: any PlantsRepository
    public let scans: any ScansRepository
    public let chat: any ChatRepository
    public let subscriptions: any SubscriptionService
    public let healthProfile: any HealthProfileRepository

    public init(
        auth: any AuthService,
        plants: any PlantsRepository,
        scans: any ScansRepository,
        chat: any ChatRepository,
        subscriptions: any SubscriptionService,
        healthProfile: any HealthProfileRepository
    ) {
        self.auth = auth
        self.plants = plants
        self.scans = scans
        self.chat = chat
        self.subscriptions = subscriptions
        self.healthProfile = healthProfile
    }
}

public extension AppDependencies {
    /// In-memory mocks — safe for `#Preview` and unit tests.
    static let mock = AppDependencies(
        auth: MockServices.Auth(),
        plants: MockServices.Plants(),
        scans: MockServices.Scans(),
        chat: MockServices.Chat(),
        subscriptions: MockServices.Subscriptions(),
        healthProfile: MockServices.HealthProfileRepo()
    )

    /// Supabase-backed live services wired by Instance 2 (Services/Live). The provided
    /// URL/anon-key are pinned into `SupabaseClientProvider` so a single shared client
    /// powers every repository.
    static func live(supabaseURL: URL, supabaseAnonKey: String) -> AppDependencies {
        SupabaseClientProvider.configure(url: supabaseURL, anonKey: supabaseAnonKey)
        let subscriptions = RevenueCatSubscriptionService()
        return AppDependencies(
            auth: SupabaseAuthService(),
            plants: SupabasePlantsRepository(),
            scans: SupabaseScansRepository(),
            chat: SupabaseChatRepository(),
            subscriptions: subscriptions,
            healthProfile: SupabaseHealthProfileRepository()
        )
    }
}
