import Foundation
import AppKit
import SwiftUI
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
    @Published private(set) var launchAtLoginStatus: LaunchAtLoginStatus = .unavailable
    @Published var launchAtLoginErrorMessage: String?
    @Published private(set) var selectedAccentColor: AccentColorOption? {
        didSet {
            guard selectedAccentColor != oldValue else { return }
            preferences.accentColorName = selectedAccentColor?.rawValue ?? "custom"
        }
    }
    @Published private(set) var customAccentColorComponents: AccentColorComponents {
        didSet {
            guard customAccentColorComponents != oldValue else { return }
            preferences.customAccentColorHex = customAccentColorComponents.hex
        }
    }
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
    private let launchAtLoginService: any LaunchAtLoginServicing
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    init(
        preferences: UserDefaultsUsagePreferences = UserDefaultsUsagePreferences(),
        launchAtLoginService: any LaunchAtLoginServicing = SystemLaunchAtLoginService()
    ) {
        self.preferences = preferences
        self.launchAtLoginService = launchAtLoginService
        self.selectedAgent = preferences.selectedAgent
        self.selectedAccentColor = preferences.accentColorName == "custom"
            ? nil
            : preferences.accentColorName.flatMap(AccentColorOption.init(rawValue:)) ?? .yellow
        self.customAccentColorComponents = preferences.customAccentColorHex
            .flatMap(AccentColorComponents.init(hex:)) ?? AccentColorOption.yellow.components
        self.launchAtLoginStatus = launchAtLoginService.status
    }

    var accentColor: Color {
        selectedAccentColor?.color ?? customAccentColorComponents.color
    }

    var accentColorName: String {
        selectedAccentColor?.name ?? "Custom"
    }

    var customAccentColor: Color {
        customAccentColorComponents.color
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

    var launchAtLoginEnabled: Bool {
        launchAtLoginStatus == .enabled || launchAtLoginStatus == .requiresApproval
    }

    var launchAtLoginAvailable: Bool {
        launchAtLoginStatus != .unavailable
    }

    var launchAtLoginRequiresApproval: Bool {
        launchAtLoginStatus == .requiresApproval
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

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(enabled)
        } catch {
            logger.error("failed to update launch at login: \(error.localizedDescription, privacy: .public)")
            launchAtLoginErrorMessage = error.localizedDescription
        }
        refreshLaunchAtLoginStatus()
    }

    func selectAccentColor(_ option: AccentColorOption) {
        selectedAccentColor = option
    }

    func setCustomAccentColor(_ color: Color) {
        guard let components = AccentColorComponents(color: color) else { return }
        customAccentColorComponents = components
        selectedAccentColor = nil
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLoginService.status
    }

    func openLoginItemsSettings() {
        launchAtLoginService.openSystemSettings()
    }

    func dismissLaunchAtLoginError() {
        launchAtLoginErrorMessage = nil
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
