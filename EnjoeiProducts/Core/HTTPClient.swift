protocol HTTPClient {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
