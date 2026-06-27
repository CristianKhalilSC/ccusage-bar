import Foundation

public struct UsageNormalizer: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.calendar = calendar
    }

    public func normalize(dailyData: Data, monthlyData: Data?, selectedAgent: String, now: Date = Date()) throws -> UsageSnapshot {
        let dailyJSON = try parseJSONObject(dailyData)
        let monthlyJSON = try monthlyData.map(parseJSONObject)
        let dailyRecords = records(from: dailyJSON)
        let monthlyRecords = monthlyJSON.map(records(from:)) ?? dailyRecords

        if dailyRecords.isEmpty && monthlyRecords.isEmpty {
            throw UsageLoadError.unreadableOutput
        }

        let detectedAgents = Array(Set((dailyRecords + monthlyRecords).map(\.agent))).sorted()
        let todayKey = Self.dayFormatter.string(from: now)
        let weekKeys = Set(lastDays(count: 7, endingAt: now))
        let monthPrefix = String(todayKey.prefix(7))

        let dailyFiltered = filtered(dailyRecords, selectedAgent: selectedAgent)
        let monthlyFiltered = filtered(monthlyRecords, selectedAgent: selectedAgent)

        let today = aggregate(dailyFiltered.filter { $0.day == todayKey })
        let weekDays = weekKeys
            .sorted()
            .map { day in DailyUsage(day: day, metrics: aggregate(dailyFiltered.filter { $0.day == day })) }
        let week = aggregate(weekDays.map(\.metrics))
        let monthDays = groupedByDay(monthlyFiltered.filter { $0.day.hasPrefix(monthPrefix) })
        let month = aggregate(monthDays.map(\.metrics))

        return UsageSnapshot(
            selectedAgent: selectedAgent,
            detectedAgents: detectedAgents,
            today: today,
            week: week,
            month: month,
            weekDays: weekDays,
            monthDays: monthDays
        )
    }

    private func parseJSONObject(_ data: Data) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            throw UsageLoadError.unreadableOutput
        }
    }

    private func filtered(_ records: [UsageRecord], selectedAgent: String) -> [UsageRecord] {
        if selectedAgent == UsageAgent.all.rawValue {
            return records
        }
        return records.filter { $0.agent.caseInsensitiveCompare(selectedAgent) == .orderedSame }
    }

    private func groupedByDay(_ records: [UsageRecord]) -> [DailyUsage] {
        let grouped = Dictionary(grouping: records, by: \.day)
        return grouped.keys.sorted().map { day in
            DailyUsage(day: day, metrics: aggregate(grouped[day, default: []]))
        }
    }

    private func aggregate(_ records: [UsageRecord]) -> TokenMetrics {
        aggregate(records.map(\.metrics))
    }

    private func aggregate(_ metrics: [TokenMetrics]) -> TokenMetrics {
        metrics.reduce(into: TokenMetrics()) { partial, next in
            partial.add(next)
        }
    }

    private func lastDays(count: Int, endingAt date: Date) -> [String] {
        (0..<count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: date)
        }.map(Self.dayFormatter.string(from:))
    }

    private func records(from json: Any) -> [UsageRecord] {
        if let array = json as? [Any] {
            return array.flatMap(records(from:))
        }

        guard let object = json as? [String: Any] else { return [] }
        let candidateKeys = ["daily", "days", "data", "usage", "entries", "results", "monthly", "months"]
        let nested = candidateKeys.flatMap { key -> [UsageRecord] in
            guard let value = object[key] else { return [] }
            return records(from: value)
        }
        if !nested.isEmpty {
            return nested
        }

        if let children = object["items"] as? [Any] {
            let childRecords = children.flatMap(records(from:))
            if !childRecords.isEmpty { return childRecords }
        }

        guard let day = string(object, keys: ["date", "day", "startDate", "month"])?.prefix(10) else {
            return []
        }

        let agent = normalizedAgent(string(object, keys: ["agent", "source", "tool", "provider", "app"]) ?? inferAgent(from: object))
        var metrics = TokenMetrics(
            input: int(object, keys: ["inputTokens", "input_tokens", "input"]),
            output: int(object, keys: ["outputTokens", "output_tokens", "output"]),
            cacheRead: int(object, keys: ["cacheReadTokens", "cache_read_tokens", "cacheRead", "cache_read"]),
            cacheCreate: int(object, keys: ["cacheCreationTokens", "cacheCreateTokens", "cache_creation_tokens", "cacheCreate", "cache_creation"]),
            reasoning: int(object, keys: ["reasoningTokens", "reasoning_tokens", "reasoningOutputTokens", "reasoning_output_tokens"]),
            cost: decimal(object, keys: ["cost", "totalCost", "total_cost", "costUSD", "cost_usd"]),
            models: models(from: object)
        )

        if let totals = object["totals"] as? [String: Any] {
            metrics.add(TokenMetrics(
                input: int(totals, keys: ["inputTokens", "input_tokens", "input"]),
                output: int(totals, keys: ["outputTokens", "output_tokens", "output"]),
                cacheRead: int(totals, keys: ["cacheReadTokens", "cache_read_tokens", "cacheRead"]),
                cacheCreate: int(totals, keys: ["cacheCreationTokens", "cacheCreateTokens", "cache_creation_tokens", "cacheCreate"]),
                reasoning: int(totals, keys: ["reasoningTokens", "reasoning_tokens", "reasoningOutputTokens"]),
                cost: decimal(totals, keys: ["cost", "totalCost", "total_cost", "costUSD"]),
                models: models(from: totals)
            ))
        }

        return [UsageRecord(day: String(day), agent: agent, metrics: metrics)]
    }

    private func inferAgent(from object: [String: Any]) -> String {
        let combined = object.values.compactMap { $0 as? String }.joined(separator: " ").lowercased()
        if combined.contains("codex") { return UsageAgent.codex.rawValue }
        if combined.contains("claude") { return UsageAgent.claude.rawValue }
        return UsageAgent.claude.rawValue
    }

    private func normalizedAgent(_ raw: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.localizedCaseInsensitiveContains("codex") { return UsageAgent.codex.rawValue }
        if value.localizedCaseInsensitiveContains("claude") { return UsageAgent.claude.rawValue }
        return value.isEmpty ? UsageAgent.claude.rawValue : value
    }

    private func string(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String { return value }
        }
        return nil
    }

    private func int(_ object: [String: Any], keys: [String]) -> Int {
        for key in keys {
            if let int = object[key] as? Int { return int }
            if let double = object[key] as? Double { return Int(double) }
            if let string = object[key] as? String, let int = Int(string) { return int }
        }
        return 0
    }

    private func decimal(_ object: [String: Any], keys: [String]) -> Decimal {
        for key in keys {
            if let double = object[key] as? Double { return Decimal(double) }
            if let int = object[key] as? Int { return Decimal(int) }
            if let string = object[key] as? String, let decimal = Decimal(string: string) { return decimal }
        }
        return 0
    }

    private func models(from object: [String: Any]) -> [String] {
        if let models = object["models"] as? [String] { return models }
        if let model = object["model"] as? String { return [model] }
        return []
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct UsageRecord {
    var day: String
    var agent: String
    var metrics: TokenMetrics
}
