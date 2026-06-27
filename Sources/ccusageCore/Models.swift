import Foundation

public enum UsageAgent: String, CaseIterable, Codable, Hashable {
    case all = "All"
    case claude = "Claude"
    case codex = "Codex"
}

public struct TokenMetrics: Codable, Equatable, Sendable {
    public var input: Int
    public var output: Int
    public var cacheRead: Int
    public var cacheCreate: Int
    public var reasoning: Int
    public var cost: Decimal
    public var models: [String]

    public init(
        input: Int = 0,
        output: Int = 0,
        cacheRead: Int = 0,
        cacheCreate: Int = 0,
        reasoning: Int = 0,
        cost: Decimal = 0,
        models: [String] = []
    ) {
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreate = cacheCreate
        self.reasoning = reasoning
        self.cost = cost
        self.models = Array(Set(models)).sorted()
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
