import Foundation

final class URLProtocolStub: URLProtocol {
    private static var stubbedData: Data?
    private static var stubbedStatusCode = 200
    private static var stubbedError: Error?
    private(set) static var lastRequest: URLRequest?

    static func stub(data: Data, statusCode: Int) {
        stubbedData = data
        stubbedStatusCode = statusCode
        stubbedError = nil
    }

    static func stub(error: Error) {
        stubbedError = error
        stubbedData = nil
    }

    static func reset() {
        stubbedData = nil
        stubbedStatusCode = 200
        stubbedError = nil
        lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request

        if let error = Self.stubbedError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.stubbedStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.stubbedData ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
