import Foundation

public enum ActiveBlockNormalizer {
    public static func normalize(_ data: Data) throws -> ActiveBlock? {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw UsageLoadError.unreadableOutput
        }

        guard let object = firstObject(in: json) else {
            return nil
        }

        let block = ActiveBlock(
            remainingMinutes: int(object, keys: ["remainingMinutes", "remaining_minutes", "minutesRemaining"]),
            burnRateTokensPerMinute: double(object, keys: ["burnRateTokensPerMinute", "burn_rate_tokens_per_minute", "burnRate"]),
            projectedTokens: int(object, keys: ["projectedTokens", "projected_tokens", "projectionTokens"]),
            projectedCost: decimal(object, keys: ["projectedCost", "projected_cost", "projectedCostUSD"])
        )

        if block.remainingMinutes == nil &&
            block.burnRateTokensPerMinute == nil &&
            block.projectedTokens == nil &&
            block.projectedCost == nil {
            return nil
        }
        return block
    }

    private static func firstObject(in value: Any) -> [String: Any]? {
        if let object = value as? [String: Any] {
            if let active = object["active"] as? Bool, active == false {
                return nil
            }
            for key in ["block", "activeBlock", "data"] {
                if let nested = object[key], let found = firstObject(in: nested) {
                    return found
                }
            }
            return object
        }

        if let array = value as? [Any] {
            return array.compactMap(firstObject(in:)).first
        }

        return nil
    }

    private static func int(_ object: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let int = object[key] as? Int { return int }
            if let double = object[key] as? Double { return Int(double) }
            if let string = object[key] as? String, let int = Int(string) { return int }
        }
        return nil
    }

    private static func double(_ object: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let double = object[key] as? Double { return double }
            if let int = object[key] as? Int { return Double(int) }
            if let string = object[key] as? String, let double = Double(string) { return double }
        }
        return nil
    }

    private static func decimal(_ object: [String: Any], keys: [String]) -> Decimal? {
        for key in keys {
            if let double = object[key] as? Double { return Decimal(double) }
            if let int = object[key] as? Int { return Decimal(int) }
            if let string = object[key] as? String, let decimal = Decimal(string: string) { return decimal }
        }
        return nil
    }
}
