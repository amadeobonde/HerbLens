import Foundation

/// Intercepts `URLSession` traffic so tests can feed canned responses without a live
/// network. Register with `URLSessionConfiguration.ephemeral` + `protocolClasses`.
///
/// Call sites push handlers onto `Self.queue`; requests dequeue them in FIFO order.
/// Unexpected requests fail the test with a readable diagnostic instead of hanging.
final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    struct Stub {
        let status: Int
        let body: Data
        let headers: [String: String]
        let bytes: [UInt8]?  // used for SSE streaming tests that need chunked delivery

        init(status: Int, body: Data, headers: [String: String] = [:], bytes: [UInt8]? = nil) {
            self.status = status
            self.body = body
            self.headers = headers
            self.bytes = bytes
        }
    }

    nonisolated(unsafe) private static var handlers: [(URLRequest) -> Stub?] = []
    nonisolated(unsafe) private static var observedRequests: [URLRequest] = []
    private static let lock = NSLock()

    static func push(stub: Stub, matching predicate: @escaping (URLRequest) -> Bool = { _ in true }) {
        lock.lock(); defer { lock.unlock() }
        handlers.append { predicate($0) ? stub : nil }
    }

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        handlers.removeAll()
        observedRequests.removeAll()
    }

    static var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return observedRequests
    }

    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.observedRequests.append(request)
        var stub: Stub?
        var remainingHandlers: [(URLRequest) -> Stub?] = []
        var matched = false
        for handler in Self.handlers {
            if !matched, let candidate = handler(request) {
                stub = candidate
                matched = true
            } else {
                remainingHandlers.append(handler)
            }
        }
        Self.handlers = remainingHandlers
        Self.lock.unlock()

        guard let stub else {
            let err = NSError(
                domain: "URLProtocolStub",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No stub queued for \(request.url?.absoluteString ?? "<nil>")"]
            )
            client?.urlProtocol(self, didFailWithError: err)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stub.status,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let bytes = stub.bytes {
            // Emit in small chunks so `URLSession.bytes(for:).lines` sees event boundaries.
            for chunk in bytes.chunked(into: 32) {
                client?.urlProtocol(self, didLoad: Data(chunk))
            }
        } else {
            client?.urlProtocol(self, didLoad: stub.body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
