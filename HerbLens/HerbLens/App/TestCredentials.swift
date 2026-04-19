#if DEBUG
import Foundation

enum TestCredentials {
    static let freeAdmin = (
        email: "admin-free@herblens.test",
        password: "herblens-free-2026",
        tier: "free"
    )
    static let proAdmin = (
        email: "admin-pro@herblens.test",
        password: "herblens-pro-2026",
        tier: "premium"
    )

    static func isAdminEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == freeAdmin.email || trimmed == proAdmin.email
    }

    static func credential(for email: String) -> (email: String, password: String, tier: String)? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed == freeAdmin.email { return freeAdmin }
        if trimmed == proAdmin.email { return proAdmin }
        return nil
    }
}
#endif
