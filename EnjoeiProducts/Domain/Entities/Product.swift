import Foundation

nonisolated struct Product: Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String
    let imageURL: URL?
    let currentPrice: Double
    let originalPrice: Double?
    let discountPercentage: Int?
}
