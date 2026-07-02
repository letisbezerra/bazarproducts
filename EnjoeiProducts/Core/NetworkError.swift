enum NetworkError: Error, Equatable {
    case invalidResponse
    case http(status: Int)
    case decoding
    case transport
}
