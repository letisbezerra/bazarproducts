import Foundation

struct Product: Equatable, Hashable, Identifiable {
    let id: Int
    let title: String
    let imageURL: URL?
    let currentPrice: Double
    let originalPrice: Double?
    let discountPercentage: Int?
}
