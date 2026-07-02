import Foundation

enum ImageURLBuilder {
    private static let baseURLString = "https://photos.enjoei.com.br/public"

    static func url(imagePublicId: String, size: String = "500x500") -> URL? {
        guard !imagePublicId.isEmpty else { return nil }
        return URL(string: "\(baseURLString)/\(size)/\(imagePublicId)")
    }
}
