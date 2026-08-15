import Foundation

public enum UsageAgent: String, CaseIterable, Codable, Hashable {
    case all = "All"
    case claude = "Claude"
    case codex = "Codex"
}

public struct ModelUsage: Codable, Equatable, Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var tokens: Int
    public var cost: Decimal

    public init(name: String, tokens: Int = 0, cost: Decimal = 0) {
        self.name = name
        self.tokens = tokens
        self.cost = cost
    }

    public mutating func add(_ other: ModelUsage) {
        tokens += other.tokens
        cost += other.cost
    }
}

public struct TokenMetrics: Codable, Equatable, Sendable {
    public var input: Int
    public var output: Int
    public var cacheRead: Int
    public var cacheCreate: Int
    public var reasoning: Int
    public var cost: Decimal
    public var models: [String]
    public var modelUsage: [ModelUsage]

    public init(
        input: Int = 0,
        output: Int = 0,
        cacheRead: Int = 0,
        cacheCreate: Int = 0,
        reasoning: Int = 0,
        cost: Decimal = 0,
        models: [String] = [],
        modelUsage: [ModelUsage] = []
    ) {
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreate = cacheCreate
        self.reasoning = reasoning
        self.cost = cost
        let allModelNames = models + modelUsage.map(\.name)
        self.models = Array(Set(allModelNames)).sorted()
        self.modelUsage = Self.mergedModelUsage(modelUsage)

        if self.modelUsage.isEmpty, self.models.count == 1 {
            self.modelUsage = [ModelUsage(
                name: self.models[0],
                tokens: input + output + cacheRead + cacheCreate + reasoning,
                cost: cost
            )]
        }
    }

    public var total: Int {
        input + output + cacheRead + cacheCreate + reasoning
    }

    public var hasUsage: Bool {
        total > 0 || cost > 0
    }

    public mutating func add(_ other: TokenMetrics) {
        input += other.input
        output += other.output
        cacheRead += other.cacheRead
        cacheCreate += other.cacheCreate
        reasoning += other.reasoning
        cost += other.cost
        models = Array(Set(models + other.models)).sorted()
        modelUsage = Self.mergedModelUsage(modelUsage + other.modelUsage)
    }

    private static func mergedModelUsage(_ values: [ModelUsage]) -> [ModelUsage] {
        var byName: [String: ModelUsage] = [:]
        for value in values where !value.name.isEmpty {
            if var existing = byName[value.name] {
                existing.add(value)
                byName[value.name] = existing
            } else {
                byName[value.name] = value
            }
        }
        return byName.values.sorted {
            if $0.tokens == $1.tokens { return $0.name < $1.name }
            return $0.tokens > $1.tokens
        }
    }
}

public struct DailyUsage: Codable, Equatable, Identifiable, Sendable {
    public var id: String { day }
    public let day: String
    public var metrics: TokenMetrics

    public init(day: String, metrics: TokenMetrics) {
        self.day = day
        self.metrics = metrics
    }
}

public struct UsageSnapshot: Codable, Equatable, Sendable {
    public var selectedAgent: String
    public var detectedAgents: [String]
    public var today: TokenMetrics
    public var week: TokenMetrics
    public var month: TokenMetrics
    public var weekDays: [DailyUsage]
    public var monthDays: [DailyUsage]

    public init(
        selectedAgent: String,
        detectedAgents: [String],
        today: TokenMetrics,
        week: TokenMetrics,
        month: TokenMetrics,
        weekDays: [DailyUsage],
        monthDays: [DailyUsage]
    ) {
        self.selectedAgent = selectedAgent
        self.detectedAgents = detectedAgents
        self.today = today
        self.week = week
        self.month = month
        self.weekDays = weekDays
        self.monthDays = monthDays
    }
}

public struct ActiveBlock: Codable, Equatable, Sendable {
    public var remainingMinutes: Int?
    public var burnRateTokensPerMinute: Double?
    public var projectedTokens: Int?
    public var projectedCost: Decimal?

    public init(
        remainingMinutes: Int? = nil,
        burnRateTokensPerMinute: Double? = nil,
        projectedTokens: Int? = nil,
        projectedCost: Decimal? = nil
    ) {
        self.remainingMinutes = remainingMinutes
        self.burnRateTokensPerMinute = burnRateTokensPerMinute
        self.projectedTokens = projectedTokens
        self.projectedCost = projectedCost
    }
}

public struct UsageLoadResult: Equatable, Sendable {
    public var snapshot: UsageSnapshot
    public var activeBlock: ActiveBlock?

    public init(snapshot: UsageSnapshot, activeBlock: ActiveBlock? = nil) {
        self.snapshot = snapshot
        self.activeBlock = activeBlock
    }
}

public enum UsageLoadError: LocalizedError, Equatable {
    case ccusageUnavailable
    case commandFailed(String)
    case unreadableOutput

    public var errorDescription: String? {
        switch self {
        case .ccusageUnavailable:
            "ccusage unavailable"
        case .commandFailed(let detail):
            detail
        case .unreadableOutput:
            "Unable to read ccusage output"
        }
    }
}
