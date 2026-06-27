import Foundation

public enum AgentSelection {
    public static func orderedAgents(detected: [String], selected: String? = nil) -> [String] {
        var values = Set(detected.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        values.insert(UsageAgent.all.rawValue)
        values.insert(UsageAgent.claude.rawValue)
        values.insert(UsageAgent.codex.rawValue)
        if let selected, !selected.isEmpty {
            values.insert(selected)
        }

        let preferred = [UsageAgent.all.rawValue, UsageAgent.claude.rawValue, UsageAgent.codex.rawValue]
        let other = values
            .subtracting(preferred)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return preferred + other
    }

    public static func shouldFetchActiveBlock(selectedAgent: String) -> Bool {
        selectedAgent == UsageAgent.all.rawValue || selectedAgent == UsageAgent.claude.rawValue
    }
}
