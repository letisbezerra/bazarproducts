import Foundation

enum PriceFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    static func string(from value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "R$ \(value)"
    }
}
