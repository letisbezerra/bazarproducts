@testable import EnjoeiProducts

enum HTTPClientMockError: Error {
    case stubbedValueTypeMismatch
    case resultNotSet
}

final class HTTPClientMock: HTTPClient {
    var result: Result<Any, Error>?
    private(set) var requestedEndpoints: [Endpoint] = []

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        requestedEndpoints.append(endpoint)

        switch result {
        case .success(let value):
            guard let typed = value as? T else {
                throw HTTPClientMockError.stubbedValueTypeMismatch
            }
            return typed
        case .failure(let error):
            throw error
        case .none:
            throw HTTPClientMockError.resultNotSet
        }
    }
}
