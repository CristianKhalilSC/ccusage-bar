import Foundation
import AppKit
import ccusageCore
import os

@MainActor
final class UsageAppModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case unavailable
        case loaded
        case failed(String)
    }

    @Published var snapshot: UsageSnapshot?
    @Published var activeBlock: ActiveBlock?
    @Published var state: LoadState = .loading
    @Published var selectedAgent: String {
        didSet {
            guard selectedAgent != oldValue else { return }
            preferences.selectedAgent = selectedAgent
            refresh()
        }
    }

    var onMenuTitleChange: ((String) -> Void)?

    private let logger = Logger(subsystem: "com.cristiancruz.ccusagebar", category: "refresh")
    private let preferences: UserDefaultsUsagePreferences
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    init(preferences: UserDefaultsUsagePreferences = UserDefaultsUsagePreferences()) {
        self.preferences = preferences
        self.selectedAgent = preferences.selectedAgent
    }

    var menuTitle: String {
        guard let snapshot else { return "-- / --" }
        return UsageFormatters.menuBar(today: snapshot.today)
    }

    var agentChoices: [String] {
        AgentSelection.orderedAgents(detected: snapshot?.detectedAgents ?? [], selected: selectedAgent)
    }

    var freshnessText: String {
        switch state {
        case .loading:
            "Loading"
        case .unavailable:
            "ccusage unavailable"
        case .loaded:
            "Updated now"
        case .failed:
            snapshot == nil ? "Unable to read ccusage output" : "Refresh failed"
        }
    }

    func start() {
        onMenuTitleChange?("-- / --")
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        refreshTask?.cancel()
        if snapshot == nil {
            state = .loading
            onMenuTitleChange?("-- / --")
        }

        refreshTask = Task {
            let service = UsageService(preferences: preferences)
            do {
                let result = try await service.load(selectedAgent: selectedAgent)
                guard !Task.isCancelled else { return }
                snapshot = result.snapshot
                activeBlock = result.activeBlock
                state = .loaded
                onMenuTitleChange?(menuTitle)
            } catch UsageLoadError.ccusageUnavailable {
                guard !Task.isCancelled else { return }
                logger.error("ccusage unavailable")
                if snapshot == nil {
                    state = .unavailable
                    onMenuTitleChange?("-- / --")
                } else {
                    state = .failed("ccusage unavailable")
                }
            } catch {
                guard !Task.isCancelled else { return }
                logger.error("refresh failed: \(error.localizedDescription, privacy: .public)")
                if snapshot == nil {
                    onMenuTitleChange?("-- / --")
                }
                state = .failed(error.localizedDescription)
            }
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
