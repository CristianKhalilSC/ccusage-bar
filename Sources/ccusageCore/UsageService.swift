import Foundation

public struct UsageService {
    public var preferences: UsagePreferences
    public var resolver: CCUsageResolver
    public var runner: CommandRunning
    public var normalizer: UsageNormalizer

    public init(
        preferences: UsagePreferences,
        resolver: CCUsageResolver = CCUsageResolver(),
        runner: CommandRunning = ProcessCommandRunner(),
        normalizer: UsageNormalizer = UsageNormalizer()
    ) {
        self.preferences = preferences
        self.resolver = resolver
        self.runner = runner
        self.normalizer = normalizer
    }

    @MainActor
    public func load(selectedAgent: String, now: Date = Date()) async throws -> UsageLoadResult {
        guard let executable = resolver.resolve(preferences: preferences) else {
            throw UsageLoadError.ccusageUnavailable
        }

        let daily = try await runJSON(executable: executable, arguments: ["daily", "--json"])
        let monthly = try await runJSON(executable: executable, arguments: ["monthly", "--json"])
        let snapshot = try normalizer.normalize(dailyData: daily, monthlyData: monthly, selectedAgent: selectedAgent, now: now)

        var activeBlock: ActiveBlock?
        if AgentSelection.shouldFetchActiveBlock(selectedAgent: selectedAgent) {
            do {
                let blockData = try await runJSON(executable: executable, arguments: ["blocks", "--active", "--json"])
                activeBlock = try ActiveBlockNormalizer.normalize(blockData)
            } catch {
                activeBlock = nil
            }
        }

        return UsageLoadResult(snapshot: snapshot, activeBlock: activeBlock)
    }

    @MainActor
    private func runJSON(executable: String, arguments: [String]) async throws -> Data {
        let result = try await runner.run(executable: executable, arguments: arguments)
        guard result.exitCode == 0 else {
            let detail = String(data: result.stderr, encoding: .utf8) ?? "ccusage command failed"
            throw UsageLoadError.commandFailed(detail)
        }
        return result.stdout
    }
}
