import Foundation

/// UI-ready error payload for the Scan flow. Keeps copy next to the model so the view
/// layer just renders — never classifies.
public struct ScanDisplayError: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let retriable: Bool

    public init(title: String, message: String, retriable: Bool) {
        self.title = title
        self.message = message
        self.retriable = retriable
    }

    public static func from(_ error: Error) -> ScanDisplayError {
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .unauthenticated:
                return ScanDisplayError(
                    title: "Sign in required",
                    message: "Your session expired. Sign in again to scan.",
                    retriable: false
                )
            case .httpStatus(let code, _):
                return ScanDisplayError(
                    title: "Identification failed",
                    message: "The server returned an error (code \(code)). Please try another photo.",
                    retriable: true
                )
            case .decodingFailed:
                return ScanDisplayError(
                    title: "Could not read the reply",
                    message: "We got something back from the server but couldn't parse it. Try again.",
                    retriable: true
                )
            case .malformedURL:
                return ScanDisplayError(
                    title: "Configuration error",
                    message: "The scan endpoint isn't configured. Contact support if this keeps happening.",
                    retriable: false
                )
            }
        }
        if let imageError = error as? ImageProcessingError {
            return ScanDisplayError(
                title: "Photo problem",
                message: imageError.userMessage,
                retriable: true
            )
        }
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return ScanDisplayError(
                title: "You're offline",
                message: "Reconnect to the internet and try again.",
                retriable: true
            )
        }
        return ScanDisplayError(
            title: "Something went wrong",
            message: error.localizedDescription,
            retriable: true
        )
    }
}

private extension ImageProcessingError {
    var userMessage: String {
        switch self {
        case .decodingFailed:
            return "That photo couldn't be opened. Try another picture."
        case .downsampleFailed:
            return "That photo was too large to process. Try taking a fresh shot."
        case .encodingFailed:
            return "We couldn't prepare that photo for upload. Try again."
        }
    }
}
