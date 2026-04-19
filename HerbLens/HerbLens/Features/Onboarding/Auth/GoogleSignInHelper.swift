import Foundation
import UIKit

// MARK: - Google Sign-In result

struct GoogleSignInResult: Sendable {
    let idToken: String
    let accessToken: String
    let email: String?
    let fullName: String?
}

enum GoogleSignInError: Error, Sendable {
    case missingToken
    case sdkNotConfigured
    case cancelled
}

// MARK: - Google Sign-In helper
//
// Requires the `GoogleSignIn` SPM package (google/GoogleSignIn-iOS).
// Add it via Xcode: File → Add Package Dependencies → https://github.com/google/GoogleSignIn-iOS
// Then set `GIDClientID` in Info.plist and add the reverse-client-ID URL scheme.

#if canImport(GoogleSignIn)
import GoogleSignIn

@MainActor
enum GoogleSignInHelper {
    static func signIn() async throws -> GoogleSignInResult {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
            let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
        else {
            throw GoogleSignInError.sdkNotConfigured
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.missingToken
        }

        return GoogleSignInResult(
            idToken: idToken,
            accessToken: result.user.accessToken.tokenString,
            email: result.user.profile?.email,
            fullName: result.user.profile?.name
        )
    }
}

#else

@MainActor
enum GoogleSignInHelper {
    static func signIn() async throws -> GoogleSignInResult {
        throw GoogleSignInError.sdkNotConfigured
    }
}

#endif
