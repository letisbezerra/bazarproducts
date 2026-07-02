import Foundation

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let method: String

    init(path: String, queryItems: [URLQueryItem] = [], method: String = "GET") {
        self.path = path
        self.queryItems = queryItems
        self.method = method
    }
}
