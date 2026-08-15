import Foundation
import ccusageCore

@main
struct UsageCoreTests {
    static func main() async throws {
        let tests = UsageCoreTests()
        try tests.formatsTokenAndCostValues()
        try tests.normalizesUnifiedDailyAndMonthlyForAllAgents()
        try tests.normalizesCurrentCCUsagePeriodShape()
        try tests.normalizesMultipleModelBreakdowns()
        try tests.normalizesCurrentCCUsageMetadataAgentShape()
        try tests.normalizesCodexReasoningTokens()
        try tests.noUsageTodayProducesZeroToday()
        try tests.malformedFieldsDoNotCrashButMissingRecordsFail()
        try tests.agentOrderingPreservesSelectedAgent()
        try tests.selectedAgentDefaultsAndEmptyState()
        try tests.resolverUsesPersistedPathThenPath()
        try await tests.serviceLoadsUsageThroughRunner()
        try await tests.serviceSkipsActiveBlockForCodex()
        try tests.activeBlockParsing()
        try tests.emptyActiveBlockParsing()
        print("ccusageCoreTests passed")
    }

    func formatsTokenAndCostValues() throws {
        try expect(UsageFormatters.tokens(0) == "0")
        try expect(UsageFormatters.tokens(6_820) == "6.8K")
        try expect(UsageFormatters.tokens(1_250_000) == "1.3M")
        try expect(UsageFormatters.cost(Decimal(string: "0.004")!) == "<$0.01")
        try expect(UsageFormatters.cost(Decimal(string: "0.72")!) == "$0.72")
    }

    func normalizesUnifiedDailyAndMonthlyForAllAgents() throws {
        let normalizer = UsageNormalizer()
        let snapshot = try normalizer.normalize(
            dailyData: fixture("unified-daily"),
            monthlyData: fixture("monthly"),
            selectedAgent: "All",
            now: date("2026-06-27")
        )

        try expect(snapshot.today.output == 9_000)
        try expect(snapshot.today.reasoning == 900)
        try expect(snapshot.today.total == 84_500)
        try expect(snapshot.today.modelUsage.map(\.name) == ["claude-sonnet-4", "gpt-5-codex"])
        try expect(snapshot.today.modelUsage.map(\.tokens) == [69_400, 15_100])
        try expect(snapshot.weekDays.count == 7)
        try expect(snapshot.month.output == 9_010)
        try expect(snapshot.detectedAgents == ["Claude", "Codex"])
    }

    func normalizesCurrentCCUsagePeriodShape() throws {
        let daily = Data(#"""
        {
          "daily": [
            {
              "agent": "all",
              "period": "2026-06-27",
              "inputTokens": 52694,
              "outputTokens": 13570,
              "cacheReadTokens": 222976,
              "cacheCreationTokens": 0,
              "totalCost": 0.2294395,
              "modelsUsed": ["gpt-5"],
              "modelBreakdowns": [
                {
                  "modelName": "gpt-5",
                  "inputTokens": 52694,
                  "outputTokens": 13570,
                  "cacheReadTokens": 222976,
                  "cacheCreationTokens": 0,
                  "cost": 0.2294395
                }
              ]
            }
          ]
        }
        """#.utf8)

        let monthly = Data(#"""
        {
          "monthly": [
            {
              "agent": "all",
              "period": "2026-06",
              "inputTokens": 55261,
              "outputTokens": 14691,
              "cacheReadTokens": 253952,
              "cacheCreationTokens": 0,
              "totalCost": 0.24773025,
              "modelsUsed": ["gpt-5"]
            }
          ]
        }
        """#.utf8)

        let snapshot = try UsageNormalizer().normalize(
            dailyData: daily,
            monthlyData: monthly,
            selectedAgent: "All",
            now: date("2026-06-27")
        )

        try expect(snapshot.today.output == 13_570)
        try expect(snapshot.today.cacheRead == 222_976)
        try expect(snapshot.today.models == ["gpt-5"])
        try expect(snapshot.today.modelUsage == [ModelUsage(name: "gpt-5", tokens: 289_240, cost: Decimal(string: "0.2294395")!)])
        try expect(snapshot.month.output == 14_691)
    }

    func normalizesMultipleModelBreakdowns() throws {
        let daily = Data(#"""
        {
          "daily": [
            {
              "period": "2026-06-27",
              "inputTokens": 100,
              "outputTokens": 50,
              "cacheReadTokens": 50,
              "modelsUsed": ["model-a", "model-b"],
              "modelBreakdowns": [
                {"modelName": "model-a", "inputTokens": 60, "outputTokens": 20, "cost": 0.08},
                {"modelName": "model-b", "inputTokens": 40, "outputTokens": 30, "cacheReadTokens": 50, "cost": 0.12}
              ]
            }
          ]
        }
        """#.utf8)

        let snapshot = try UsageNormalizer().normalize(
            dailyData: daily,
            monthlyData: nil,
            selectedAgent: "All",
            now: date("2026-06-27")
        )

        try expect(snapshot.today.modelUsage.map(\.name) == ["model-b", "model-a"])
        try expect(snapshot.today.modelUsage.map(\.tokens) == [120, 80])
        try expect(snapshot.today.modelUsage.reduce(0) { $0 + $1.tokens } == snapshot.today.total)
    }

    func normalizesCurrentCCUsageMetadataAgentShape() throws {
        let daily = Data(#"""
        {
          "daily": [
            {
              "agent": "all",
              "period": "2026-06-27",
              "inputTokens": 52694,
              "outputTokens": 13570,
              "cacheReadTokens": 222976,
              "cacheCreationTokens": 0,
              "totalCost": 0.2294395,
              "metadata": {
                "agents": ["codex"]
              },
              "modelsUsed": ["gpt-5"]
            }
          ]
        }
        """#.utf8)

        let monthly = Data(#"""
        {
          "monthly": [
            {
              "agent": "all",
              "period": "2026-06",
              "inputTokens": 55261,
              "outputTokens": 14691,
              "cacheReadTokens": 253952,
              "cacheCreationTokens": 0,
              "totalCost": 0.24773025,
              "metadata": {
                "agents": ["codex"]
              },
              "modelsUsed": ["gpt-5"]
            }
          ]
        }
        """#.utf8)

        let codexSnapshot = try UsageNormalizer().normalize(
            dailyData: daily,
            monthlyData: monthly,
            selectedAgent: "Codex",
            now: date("2026-06-27")
        )
        try expect(codexSnapshot.today.output == 13_570)
        try expect(codexSnapshot.month.output == 14_691)
        try expect(codexSnapshot.detectedAgents == ["Codex"])

        let claudeSnapshot = try UsageNormalizer().normalize(
            dailyData: daily,
            monthlyData: monthly,
            selectedAgent: "Claude",
            now: date("2026-06-27")
        )
        try expect(claudeSnapshot.today.output == 0)
    }

    func normalizesCodexReasoningTokens() throws {
        let snapshot = try UsageNormalizer().normalize(
            dailyData: fixture("unified-daily"),
            monthlyData: fixture("monthly"),
            selectedAgent: "Codex",
            now: date("2026-06-27")
        )

        try expect(snapshot.today.output == 2_200)
        try expect(snapshot.today.reasoning == 900)
        try expect(snapshot.today.models == ["gpt-5-codex"])
    }

    func noUsageTodayProducesZeroToday() throws {
        let snapshot = try UsageNormalizer().normalize(
            dailyData: fixture("no-usage-today"),
            monthlyData: nil,
            selectedAgent: "All",
            now: date("2026-06-27")
        )

        try expect(snapshot.today.output == 0)
        try expect(snapshot.today.cost == 0)
    }

    func malformedFieldsDoNotCrashButMissingRecordsFail() throws {
        _ = try UsageNormalizer().normalize(
            dailyData: fixture("malformed"),
            monthlyData: nil,
            selectedAgent: "All",
            now: date("2026-06-27")
        )

        do {
            _ = try UsageNormalizer().normalize(
                dailyData: Data("{}".utf8),
                monthlyData: nil,
                selectedAgent: "All",
                now: date("2026-06-27")
            )
            throw TestFailure("missing records did not throw")
        } catch UsageLoadError.unreadableOutput {
            return
        }
    }

    func agentOrderingPreservesSelectedAgent() throws {
        try expect(
            AgentSelection.orderedAgents(detected: ["Cursor", "Codex"], selected: "Ghost") ==
            ["All", "Claude", "Codex", "Cursor", "Ghost"]
        )
    }

    func selectedAgentDefaultsAndEmptyState() throws {
        let preferences = InMemoryUsagePreferences()
        try expect(preferences.selectedAgent == "All")
        preferences.selectedAgent = "Ghost"
        try expect(preferences.selectedAgent == "Ghost")

        let snapshot = try UsageNormalizer().normalize(
            dailyData: fixture("unified-daily"),
            monthlyData: fixture("monthly"),
            selectedAgent: "Ghost",
            now: date("2026-06-27")
        )
        try expect(snapshot.today.output == 0)
        try expect(snapshot.selectedAgent == "Ghost")
        try expect(AgentSelection.orderedAgents(detected: snapshot.detectedAgents, selected: "Ghost").contains("Ghost"))
    }

    func resolverUsesPersistedPathThenPath() throws {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let executable = temporaryDirectory.appendingPathComponent("ccusage")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let preferences = InMemoryUsagePreferences()
        let resolver = CCUsageResolver(environment: ["PATH": temporaryDirectory.path])
        let resolved = resolver.resolve(preferences: preferences)

        try expect(resolved == executable.path)
        try expect(preferences.resolvedCCUsagePath == executable.path)
        try expect(resolver.resolve(preferences: preferences) == executable.path)
    }

    func serviceLoadsUsageThroughRunner() async throws {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let executable = temporaryDirectory.appendingPathComponent("ccusage")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let preferences = InMemoryUsagePreferences(resolvedCCUsagePath: executable.path)
        let runner = MockRunner(results: [
            ["daily", "--json"]: fixture("unified-daily"),
            ["monthly", "--json"]: fixture("monthly"),
            ["blocks", "--active", "--json"]: Data(#"{"active":false}"#.utf8)
        ])
        let service = UsageService(
            preferences: preferences,
            resolver: CCUsageResolver(environment: [:]),
            runner: runner
        )

        let result = try await service.load(selectedAgent: "All", now: date("2026-06-27"))
        try expect(result.snapshot.today.output == 9_000)
        try expect(result.activeBlock == nil)
    }

    func serviceSkipsActiveBlockForCodex() async throws {
        let executable = try temporaryCCUsageExecutable()
        let preferences = InMemoryUsagePreferences(resolvedCCUsagePath: executable.path)
        let runner = MockRunner(results: [
            ["daily", "--json"]: fixture("unified-daily"),
            ["monthly", "--json"]: fixture("monthly")
        ])
        let service = UsageService(
            preferences: preferences,
            resolver: CCUsageResolver(environment: [:]),
            runner: runner
        )

        let result = try await service.load(selectedAgent: "Codex", now: date("2026-06-27"))
        try expect(result.snapshot.today.output == 2_200)
        try expect(result.activeBlock == nil)
        try expect(!runner.calls.contains(["blocks", "--active", "--json"]))
        try? FileManager.default.removeItem(at: executable.deletingLastPathComponent())
    }

    func activeBlockParsing() throws {
        let data = Data(#"{"active":true,"remaining_minutes":82,"burnRate":41.5,"projected_tokens":18400,"projected_cost":1.88}"#.utf8)
        let block = try ActiveBlockNormalizer.normalize(data)
        try expect(block?.remainingMinutes == 82)
        try expect(block?.projectedTokens == 18_400)
    }

    func emptyActiveBlockParsing() throws {
        let inactive = try ActiveBlockNormalizer.normalize(Data(#"{"active":false}"#.utf8))
        let empty = try ActiveBlockNormalizer.normalize(Data("[]".utf8))
        try expect(inactive == nil)
        try expect(empty == nil)
    }

    private func fixture(_ name: String) -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try! Data(contentsOf: url)
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: value)!
    }

    private func temporaryCCUsageExecutable() throws -> URL {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let executable = temporaryDirectory.appendingPathComponent("ccusage")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        return executable
    }

    private func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String = "assertion failed",
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard condition() else { throw TestFailure("\(message) at \(file):\(line)") }
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

final class MockRunner: CommandRunning, @unchecked Sendable {
    let results: [[String]: Data]
    private(set) var calls: [[String]] = []

    init(results: [[String]: Data]) {
        self.results = results
    }

    func run(executable: String, arguments: [String]) async throws -> CommandResult {
        calls.append(arguments)
        if let data = results[arguments] {
            return CommandResult(stdout: data)
        }
        return CommandResult(stdout: Data(), stderr: Data("missing result".utf8), exitCode: 1)
    }
}
