import Foundation

public enum UsageFormatters {
    public static func tokens(_ value: Int) -> String {
        let absolute = abs(value)
        let sign = value < 0 ? "-" : ""
        if absolute >= 1_000_000 {
            return "\(sign)\(oneDecimal(Double(absolute) / 1_000_000))M"
        }
        if absolute >= 1_000 {
            return "\(sign)\(oneDecimal(Double(absolute) / 1_000))K"
        }
        return "\(value)"
    }

    public static func cost(_ value: Decimal) -> String {
        if value > 0 && value < Decimal(string: "0.01")! {
            return "<$0.01"
        }
        return String(format: "$%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    public static func menuBar(today: TokenMetrics) -> String {
        "\(tokens(today.output)) / \(cost(today.cost))"
    }

    private static func oneDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }
}
