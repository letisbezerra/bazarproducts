import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let method: HTTPMethod

    init(path: String, queryItems: [URLQueryItem] = [], method: HTTPMethod = .get) {
        self.path = path
        self.queryItems = queryItems
        self.method = method
    }
}
