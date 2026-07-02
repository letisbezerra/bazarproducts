import Foundation

struct Product: Equatable, Identifiable {
    let id: Int
    let title: String
    let imageURL: URL?
    let currentPrice: Double
    let originalPrice: Double?
    let discountPercentage: Int?
}
