import SwiftUI
import ccusageCore

private enum Brand {
    static let border = Color(red: 38 / 255, green: 38 / 255, blue: 38 / 255)
    static let secondaryText = Color.white.opacity(0.56)
}

struct PopoverView: View {
    @ObservedObject var model: UsageAppModel
    @State private var tab: UsageTab = .today
    let onContentHeightChange: (CGFloat) -> Void

    init(model: UsageAppModel, onContentHeightChange: @escaping (CGFloat) -> Void = { _ in }) {
        self.model = model
        self.onContentHeightChange = onContentHeightChange
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, alignment: .top)
            footer
        }
        .frame(width: 390)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            FrostedBackdrop(accentColor: model.accentColor)
        }
        .foregroundStyle(.white)
        .tint(model.accentColor)
        .environment(\.appAccentColor, model.accentColor)
        .preferredColorScheme(.dark)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: PopoverHeightPreferenceKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(PopoverHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            onContentHeightChange(height)
        }
        .alert("Unable to Change Launch at Login", isPresented: launchAtLoginErrorPresented) {
            Button("OK", action: model.dismissLaunchAtLoginError)
        } message: {
            Text(model.launchAtLoginErrorMessage ?? "The login item could not be updated.")
        }
    }

    private var header: some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                Wordmark()
                Spacer()
                agentMenu
            }

            tabSelector
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var tabSelector: some View {
        HStack(spacing: 7) {
            ForEach(UsageTab.allCases) { option in
                Button {
                    withAnimation(.snappy(duration: 0.24)) {
                        tab = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tab == option ? model.accentColor : Brand.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frostedGlassSurface(
                    cornerRadius: 16,
                    tint: tab == option ? model.accentColor.opacity(0.17) : nil
                )
            }
        }
    }

    private var agentMenu: some View {
        Menu {
            Picker("Agent", selection: $model.selectedAgent) {
                ForEach(model.agentChoices, id: \.self) { agent in
                    Text(agent).tag(agent)
                }
            }
        } label: {
            agentMenuLabel
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var agentMenuLabel: some View {
        HStack(spacing: 8) {
            Text(model.selectedAgent == UsageAgent.all.rawValue ? "All agents" : model.selectedAgent)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Brand.secondaryText)
        }
        .font(.system(size: 11, weight: .semibold))
        .textCase(.uppercase)
        .padding(.horizontal, 11)
        .frame(height: 30)
        .frostedGlassSurface(cornerRadius: 15, tint: model.accentColor.opacity(0.10))
    }

    @ViewBuilder private var content: some View {
        if model.state == .unavailable && model.snapshot == nil {
            UnavailableView(retry: model.refresh)
        } else if let snapshot = model.snapshot {
            DashboardView(
                tab: tab,
                snapshot: snapshot,
                activeBlock: AgentSelection.shouldFetchActiveBlock(selectedAgent: model.selectedAgent)
                    ? model.activeBlock
                    : nil
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        } else {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                    .tint(model.accentColor)
                Text("Reading usage")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Brand.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .shadow(color: statusColor.opacity(0.35), radius: 4)
            Text(model.freshnessText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Brand.secondaryText)
            Spacer()
            footerActions
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
        }
    }

    @ViewBuilder private var footerActions: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                footerActionContent
            }
        } else {
            footerActionContent
        }
    }

    private var footerActionContent: some View {
        HStack(spacing: 8) {
            Button(action: model.refresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(model.accentColor)
            }
            .buttonStyle(FooterButtonStyle(tint: model.accentColor.opacity(0.13)))
            .keyboardShortcut("r", modifiers: .command)

            footerSecondaryActions
        }
    }

    private var footerSecondaryActions: some View {
        HStack(spacing: 0) {
            launchAtLoginMenu

            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 14)

            Button(action: model.quit) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Brand.secondaryText)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Quit ccusage Bar")
            .keyboardShortcut("q", modifiers: .command)
        }
        .frostedGlassSurface(cornerRadius: 14)
    }

    private var launchAtLoginMenu: some View {
        Menu {
            Toggle("Launch at Login", isOn: launchAtLoginBinding)
                .disabled(!model.launchAtLoginAvailable)
            Divider()
            Menu {
                ForEach(AccentColorOption.allCases) { option in
                    Toggle(isOn: accentColorBinding(for: option)) {
                        Label {
                            Text(option.name)
                        } icon: {
                            Image(nsImage: option.swatchImage)
                        }
                    }
                }
                Divider()
                Button(action: showCustomAccentColorPicker) {
                    Label {
                        Text("Custom…")
                    } icon: {
                        Image(nsImage: model.customAccentColorComponents.swatchImage)
                    }
                }
            } label: {
                Label("Accent Color: \(model.accentColorName)", systemImage: "paintpalette")
            }
            if model.launchAtLoginRequiresApproval {
                Divider()
                Button("Approve in System Settings...") {
                    model.openLoginItemsSettings()
                }
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Brand.secondaryText)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Settings")
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.launchAtLoginEnabled },
            set: { enabled in model.setLaunchAtLogin(enabled) }
        )
    }

    private func accentColorBinding(for option: AccentColorOption) -> Binding<Bool> {
        Binding(
            get: { model.selectedAccentColor == option },
            set: { isSelected in
                if isSelected {
                    model.selectAccentColor(option)
                }
            }
        )
    }

    private func showCustomAccentColorPicker() {
        let initialColor = model.customAccentColor
        model.setCustomAccentColor(initialColor)
        DispatchQueue.main.async { [weak model] in
            AccentColorPanelController.shared.show(color: initialColor) { [weak model] color in
                model?.setCustomAccentColor(color)
            }
        }
    }

    private var launchAtLoginErrorPresented: Binding<Bool> {
        Binding(
            get: { model.launchAtLoginErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    model.dismissLaunchAtLoginError()
                }
            }
        )
    }

    private var statusColor: Color {
        switch model.state {
        case .loaded: model.accentColor
        case .loading: Brand.secondaryText
        case .unavailable, .failed: Color.orange
        }
    }
}

private struct PopoverHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum UsageTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

private struct Wordmark: View {
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 5) {
            Text("ccusage")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(-1.1)
            Text("BAR")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(accentColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ccusage Bar")
    }
}

private struct DashboardView: View {
    let tab: UsageTab
    let snapshot: UsageSnapshot
    let activeBlock: ActiveBlock?

    private var metrics: TokenMetrics {
        switch tab {
        case .today: snapshot.today
        case .week: snapshot.week
        case .month: snapshot.month
        }
    }

    private var chartDays: [DailyUsage] {
        switch tab {
        case .today, .week: snapshot.weekDays
        case .month: snapshot.monthDays
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HeroCard(period: tab.rawValue, metrics: metrics)
            if let activeBlock {
                ActiveBlockCard(block: activeBlock)
            }
            TokenCompositionCard(metrics: metrics)
            MetricTiles(metrics: metrics)
            ModelUsageCard(metrics: metrics)
            UsageChart(
                title: tab == .month ? "This month" : "This week",
                cost: tab == .month ? snapshot.month.cost : snapshot.week.cost,
                days: chartDays
            )
        }
        .animation(.easeOut(duration: 0.18), value: tab)
    }
}

private struct HeroCard: View {
    let period: String
    let metrics: TokenMetrics

    var body: some View {
        HStack(spacing: 0) {
            HeroValue(value: UsageFormatters.cost(metrics.cost), label: period.uppercased(), accent: true)
            Rectangle().fill(Brand.border).frame(width: 1, height: 52)
            HeroValue(value: UsageFormatters.tokens(metrics.total), label: "TOTAL TOKENS", accent: false)
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

private struct HeroValue: View {
    @Environment(\.appAccentColor) private var accentColor

    let value: String
    let label: String
    let accent: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent ? accentColor : Color.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Brand.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ActiveBlockCard: View {
    @Environment(\.appAccentColor) private var accentColor

    let block: ActiveBlock

    private var stats: [(String, String)] {
        var values: [(String, String)] = []
        if let remaining = block.remainingMinutes { values.append(("Remaining", "\(remaining)m")) }
        if let burn = block.burnRateTokensPerMinute { values.append(("Burn", "\(Int(burn))/m")) }
        if let projected = block.projectedTokens { values.append(("Projected", UsageFormatters.tokens(projected))) }
        if let cost = block.projectedCost { values.append(("Cost", UsageFormatters.cost(cost))) }
        return values
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11))
                .foregroundStyle(accentColor)
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.0)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Brand.secondaryText)
                    Text(stat.1)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct TokenCompositionCard: View {
    @Environment(\.appAccentColor) private var accentColor

    let metrics: TokenMetrics

    private var segments: [TokenSegment] {
        [
            TokenSegment(label: "Input", value: metrics.input, color: accentColor),
            TokenSegment(label: "Output", value: metrics.output, color: Color.white.opacity(0.25)),
            TokenSegment(label: "Cache read", value: metrics.cacheRead, color: Color.white.opacity(0.40)),
            TokenSegment(label: "Cache create", value: metrics.cacheCreate, color: Color.white.opacity(0.62))
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Token composition")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("Total \(UsageFormatters.tokens(metrics.total))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Brand.secondaryText)
            }
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    ForEach(segments) { segment in
                        segment.color.frame(width: segmentWidth(segment.value, available: proxy.size.width))
                    }
                    if metrics.reasoning > 0 {
                        Color.white.opacity(0.8)
                            .frame(width: segmentWidth(metrics.reasoning, available: proxy.size.width))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .frame(height: 9)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), alignment: .leading, spacing: 7) {
                ForEach(segments) { segment in
                    CompositionLegend(segment: segment, total: metrics.total)
                }
            }
            if metrics.reasoning > 0 {
                Text("Reasoning \(UsageFormatters.tokens(metrics.reasoning))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Brand.secondaryText)
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func segmentWidth(_ value: Int, available: CGFloat) -> CGFloat {
        guard metrics.total > 0 else { return 0 }
        return max(value > 0 ? 2 : 0, available * CGFloat(value) / CGFloat(metrics.total))
    }
}

private struct TokenSegment: Identifiable {
    let label: String
    let value: Int
    let color: Color
    var id: String { label }
}

private struct CompositionLegend: View {
    let segment: TokenSegment
    let total: Int

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(segment.value) / Double(total) * 100).rounded())
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(segment.color).frame(width: 6, height: 6)
            Text(segment.label).foregroundStyle(Brand.secondaryText)
            Spacer(minLength: 4)
            Text("\(percentage)%").monospacedDigit()
        }
        .font(.system(size: 9, weight: .medium))
    }
}

private struct MetricTiles: View {
    @Environment(\.appAccentColor) private var accentColor

    let metrics: TokenMetrics

    private var items: [MetricItem] {
        [
            MetricItem(label: "Input", value: metrics.input, icon: "arrow.up.right"),
            MetricItem(label: "Output", value: metrics.output, icon: "arrow.down.to.line"),
            MetricItem(label: "Cache read", value: metrics.cacheRead, icon: "line.3.horizontal"),
            MetricItem(label: "Cache create", value: metrics.cacheCreate, icon: "plus.square")
        ]
    }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Image(systemName: item.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)
                    Text(item.label)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Brand.secondaryText)
                        .lineLimit(1)
                    Text(UsageFormatters.tokens(item.value))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(9)
                .frostedCardSurface(cornerRadius: 10)
            }
        }
    }
}

private struct MetricItem: Identifiable {
    let label: String
    let value: Int
    let icon: String
    var id: String { label }
}

private struct ModelUsageCard: View {
    @Environment(\.appAccentColor) private var accentColor

    let metrics: TokenMetrics

    private var rows: [ModelUsage] {
        if !metrics.modelUsage.isEmpty { return metrics.modelUsage }
        return metrics.models.map { ModelUsage(name: $0) }
    }

    private var attributedTokens: Int {
        rows.reduce(0) { $0 + $1.tokens }
    }

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Text("Models")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text("Share of tokens")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Brand.secondaryText)
                }

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, usage in
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(modelColor(index))
                                .frame(width: 6, height: 6)
                            Text(usage.name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 8)
                            if usage.tokens > 0 {
                                Text(UsageFormatters.tokens(usage.tokens))
                                    .foregroundStyle(Brand.secondaryText)
                                Text("\(percentage(for: usage))%")
                                    .frame(width: 31, alignment: .trailing)
                            } else {
                                Text("Breakdown unavailable")
                                    .foregroundStyle(Brand.secondaryText)
                            }
                        }
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.07))
                                Capsule()
                                    .fill(modelColor(index))
                                    .frame(width: barWidth(for: usage, available: proxy.size.width))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
            .padding(12)
            .cardStyle()
        }
    }

    private func percentage(for usage: ModelUsage) -> Int {
        guard attributedTokens > 0 else { return 0 }
        return Int((Double(usage.tokens) / Double(attributedTokens) * 100).rounded())
    }

    private func barWidth(for usage: ModelUsage, available: CGFloat) -> CGFloat {
        guard attributedTokens > 0 else { return 0 }
        return available * CGFloat(usage.tokens) / CGFloat(attributedTokens)
    }

    private func modelColor(_ index: Int) -> Color {
        switch index {
        case 0: accentColor
        case 1: Color.white.opacity(0.62)
        case 2: Color.white.opacity(0.40)
        default: Color.white.opacity(0.24)
        }
    }
}

private struct UsageChart: View {
    @Environment(\.appAccentColor) private var accentColor

    let title: String
    let cost: Decimal
    let days: [DailyUsage]

    private var maxOutput: Int { max(days.map { $0.metrics.output }.max() ?? 0, 1) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(UsageFormatters.cost(cost))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)
            }
            HStack(alignment: .bottom, spacing: days.count > 14 ? 2 : 8) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(index == days.count - 1 ? accentColor : Color.white.opacity(0.20))
                            .frame(height: max(4, CGFloat(day.metrics.output) / CGFloat(maxOutput) * 52))
                        Text(dayLabel(day.day, dense: days.count > 14))
                            .font(.system(size: days.count > 14 ? 6.5 : 8, weight: .medium))
                            .foregroundStyle(Brand.secondaryText)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70, alignment: .bottom)
        }
        .padding(12)
        .cardStyle()
    }

    private func dayLabel(_ rawDay: String, dense: Bool) -> String {
        guard let date = Self.inputFormatter.date(from: rawDay) else { return String(rawDay.suffix(2)) }
        return (dense ? Self.dayNumberFormatter : Self.weekdayFormatter).string(from: date)
    }

    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter
    }()
    private static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d"
        return formatter
    }()
}

private struct FooterButtonStyle: ButtonStyle {
    let tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .frame(height: 28)
            .opacity(configuration.isPressed ? 0.70 : 1)
            .frostedGlassSurface(cornerRadius: 14, tint: tint)
    }
}

private extension View {
    func cardStyle() -> some View {
        frostedCardSurface(cornerRadius: 13)
    }
}

private struct UnavailableView: View {
    @Environment(\.appAccentColor) private var accentColor

    let retry: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(accentColor)
            Text("ccusage unavailable").font(.system(size: 14, weight: .semibold))
            Text("Install ccusage or check your PATH, then retry.")
                .font(.system(size: 11))
                .foregroundStyle(Brand.secondaryText)
            Button("Retry", action: retry).buttonStyle(FooterButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}

struct PopoverView_Previews: PreviewProvider {
    static var previews: some View {
        let model = UsageAppModel()
        model.snapshot = MockUsage.snapshot
        model.activeBlock = MockUsage.activeBlock
        model.state = .loaded
        return PopoverView(model: model)
    }
}
