import Foundation

public struct CCUsageResolver {
    public var fileManager: FileManager
    public var environment: [String: String]

    public init(fileManager: FileManager = .default, environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.fileManager = fileManager
        self.environment = environment
    }

    public func resolve(preferences: UsagePreferences) -> String? {
        if let persisted = preferences.resolvedCCUsagePath, isExecutable(persisted) {
            return persisted
        }

        for candidate in pathCandidates() where isExecutable(candidate) {
            preferences.resolvedCCUsagePath = candidate
            return candidate
        }

        for candidate in ["/opt/homebrew/bin/ccusage", "/usr/local/bin/ccusage"] where isExecutable(candidate) {
            preferences.resolvedCCUsagePath = candidate
            return candidate
        }

        return nil
    }

    private func pathCandidates() -> [String] {
        let path = environment["PATH"] ?? ""
        return path
            .split(separator: ":")
            .map { String($0) + "/ccusage" }
    }

    private func isExecutable(_ path: String) -> Bool {
        fileManager.isExecutableFile(atPath: path)
    }
}
