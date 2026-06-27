import Foundation

public enum MockUsage {
    public static let snapshot = UsageSnapshot(
        selectedAgent: UsageAgent.all.rawValue,
        detectedAgents: [UsageAgent.claude.rawValue, UsageAgent.codex.rawValue],
        today: TokenMetrics(
            input: 42_100,
            output: 6_820,
            cacheRead: 18_500,
            cacheCreate: 2_100,
            reasoning: 730,
            cost: Decimal(string: "0.72")!,
            models: ["claude-sonnet-4", "gpt-5-codex"]
        ),
        week: TokenMetrics(input: 210_000, output: 31_450, cacheRead: 81_000, cacheCreate: 9_200, reasoning: 2_600, cost: Decimal(string: "3.64")!, models: ["claude-sonnet-4", "gpt-5-codex"]),
        month: TokenMetrics(input: 830_000, output: 119_000, cacheRead: 310_000, cacheCreate: 33_000, reasoning: 8_400, cost: Decimal(string: "15.31")!, models: ["claude-sonnet-4", "gpt-5-codex"]),
        weekDays: [
            DailyUsage(day: "2026-06-21", metrics: TokenMetrics(output: 1_200, cost: 0.12)),
            DailyUsage(day: "2026-06-22", metrics: TokenMetrics(output: 3_900, cost: 0.34)),
            DailyUsage(day: "2026-06-23", metrics: TokenMetrics(output: 6_000, cost: 0.66)),
            DailyUsage(day: "2026-06-24", metrics: TokenMetrics(output: 2_400, cost: 0.21)),
            DailyUsage(day: "2026-06-25", metrics: TokenMetrics(output: 5_100, cost: 0.59)),
            DailyUsage(day: "2026-06-26", metrics: TokenMetrics(output: 6_030, cost: 0.70)),
            DailyUsage(day: "2026-06-27", metrics: TokenMetrics(output: 6_820, cost: 0.72))
        ],
        monthDays: (1...27).map { day in
            DailyUsage(day: String(format: "2026-06-%02d", day), metrics: TokenMetrics(output: day * 230, cost: Decimal(day) / 100))
        }
    )

    public static let activeBlock = ActiveBlock(
        remainingMinutes: 82,
        burnRateTokensPerMinute: 41.5,
        projectedTokens: 18_400,
        projectedCost: Decimal(string: "1.88")
    )
}
