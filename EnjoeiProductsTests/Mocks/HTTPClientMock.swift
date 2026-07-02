@testable import EnjoeiProducts

final class HTTPClientMock: HTTPClient {
    var result: Result<Any, Error>?
    private(set) var requestedEndpoints: [Endpoint] = []

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        requestedEndpoints.append(endpoint)

        switch result {
        case .success(let value):
            guard let typed = value as? T else {
                fatalError("HTTPClientMock stubbed value doesn't match the requested type \(T.self)")
            }
            return typed
        case .failure(let error):
            throw error
        case .none:
            fatalError("HTTPClientMock.result not set before calling send(_:)")
        }
    }
}
