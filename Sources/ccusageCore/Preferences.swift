import Foundation

public protocol UsagePreferences: AnyObject {
    var selectedAgent: String { get set }
    var resolvedCCUsagePath: String? { get set }
}

public final class UserDefaultsUsagePreferences: UsagePreferences {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var selectedAgent: String {
        get { defaults.string(forKey: "selectedAgent") ?? UsageAgent.all.rawValue }
        set { defaults.set(newValue, forKey: "selectedAgent") }
    }

    public var resolvedCCUsagePath: String? {
        get { defaults.string(forKey: "resolvedCCUsagePath") }
        set { defaults.set(newValue, forKey: "resolvedCCUsagePath") }
    }

    public var accentColorName: String? {
        get { defaults.string(forKey: "accentColor") }
        set { defaults.set(newValue, forKey: "accentColor") }
    }

    public var customAccentColorHex: String? {
        get { defaults.string(forKey: "customAccentColor") }
        set { defaults.set(newValue, forKey: "customAccentColor") }
    }
}

public final class InMemoryUsagePreferences: UsagePreferences {
    public var selectedAgent: String
    public var resolvedCCUsagePath: String?

    public init(selectedAgent: String = UsageAgent.all.rawValue, resolvedCCUsagePath: String? = nil) {
        self.selectedAgent = selectedAgent
        self.resolvedCCUsagePath = resolvedCCUsagePath
    }
}
