import Foundation

final class URLSessionHTTPClient: HTTPClient {
    private static let defaultBaseURL = URL(string: "https://www.enjoei.com.br/api/v5")!

    private let baseURL: URL
    private let session: URLSession
    private let logger: AppLogger

    init(
        baseURL: URL = URLSessionHTTPClient.defaultBaseURL,
        session: URLSession = .shared,
        logger: AppLogger = OSLogAppLogger()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.logger = logger
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try makeRequest(for: endpoint)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.log("Transport error for \(endpoint.path): \(error)", category: .network)
            throw NetworkError.transport
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.http(status: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.log("Decoding error for \(endpoint.path): \(error)", category: .network)
            throw NetworkError.decoding
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidResponse
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        return request
    }
}
