import Foundation

public protocol AuthService: Sendable {
    var currentUserID: String? { get async }
    func signUp(email: String, password: String) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() async throws
    func sendMagicLink(email: String) async throws
}
