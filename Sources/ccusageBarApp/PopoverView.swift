import SwiftUI
import ccusageCore

struct PopoverView: View {
    @ObservedObject var model: UsageAppModel
    @State private var tab: UsageTab = .today

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.08))
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Divider().overlay(Color.white.opacity(0.08))
            footer
        }
        .frame(width: 360, height: 520)
        .background(Color(red: 0.06, green: 0.06, blue: 0.055))
        .foregroundStyle(.white)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ccusage Bar")
                        .font(.headline)
                    Text(model.freshnessText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $model.selectedAgent) {
                    ForEach(model.agentChoices, id: \.self) { agent in
                        Text(agent).tag(agent)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 128)
            }

            Picker("", selection: $tab) {
                ForEach(UsageTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
    }

    @ViewBuilder private var content: some View {
        if model.state == .unavailable && model.snapshot == nil {
            UnavailableView(retry: model.refresh)
        } else if let snapshot = model.snapshot {
            ScrollView {
                VStack(spacing: 14) {
                    if let activeBlock = model.activeBlock,
                       AgentSelection.shouldFetchActiveBlock(selectedAgent: model.selectedAgent) {
                        ActiveBlockStrip(block: activeBlock)
                    }
                    switch tab {
                    case .today:
                        TodayView(snapshot: snapshot)
                    case .week:
                        PeriodView(title: "Week", metrics: snapshot.week, days: snapshot.weekDays, includeDenseFallback: false)
                    case .month:
                        PeriodView(title: "Month", metrics: snapshot.month, days: snapshot.monthDays, includeDenseFallback: true)
                    }
                }
                .padding(14)
            }
        } else {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Refresh", action: model.refresh)
                .keyboardShortcut("r", modifiers: .command)
            Spacer()
            Button("Quit", action: model.quit)
                .keyboardShortcut("q", modifiers: .command)
        }
        .padding(14)
    }
}

enum UsageTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

struct TodayView: View {
    let snapshot: UsageSnapshot

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(UsageFormatters.cost(snapshot.today.cost))
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Total tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(UsageFormatters.tokens(snapshot.today.total))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
            }

            MetricsRows(metrics: snapshot.today)
            BarChart(days: snapshot.weekDays)
            SummaryRow(title: "Month", metrics: snapshot.month)
        }
    }
}

struct PeriodView: View {
    let title: String
    let metrics: TokenMetrics
    let days: [DailyUsage]
    let includeDenseFallback: Bool

    var body: some View {
        VStack(spacing: 14) {
            SummaryRow(title: title, metrics: metrics)
            if includeDenseFallback && days.count > 18 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("High-usage days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(days.sorted { $0.metrics.output > $1.metrics.output }.prefix(6)) { day in
                        HStack {
                            Text(day.day)
                            Spacer()
                            Text(UsageFormatters.tokens(day.metrics.output))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            } else {
                BarChart(days: days)
            }
            MetricsRows(metrics: metrics)
        }
    }
}

struct SummaryRow: View {
    let title: String
    let metrics: TokenMetrics

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(UsageFormatters.cost(metrics.cost))
                .font(.headline)
                .foregroundStyle(Color(red: 1.0, green: 0.79, blue: 0.18))
            Text(UsageFormatters.tokens(metrics.total))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct MetricsRows: View {
    let metrics: TokenMetrics

    var body: some View {
        VStack(spacing: 7) {
            MetricRow(label: "Input", value: UsageFormatters.tokens(metrics.input))
            MetricRow(label: "Output", value: UsageFormatters.tokens(metrics.output))
            MetricRow(label: "Cache read", value: UsageFormatters.tokens(metrics.cacheRead))
            MetricRow(label: "Cache create", value: UsageFormatters.tokens(metrics.cacheCreate))
            MetricRow(label: "Total tokens", value: UsageFormatters.tokens(metrics.total))
            MetricRow(label: "Models", value: metrics.models.isEmpty ? "-" : metrics.models.joined(separator: ", "))
            if metrics.reasoning > 0 {
                MetricRow(label: "Reasoning", value: UsageFormatters.tokens(metrics.reasoning))
            }
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}

struct BarChart: View {
    let days: [DailyUsage]

    var body: some View {
        let maxOutput = max(days.map { $0.metrics.output }.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 1.0, green: 0.79, blue: 0.18))
                        .frame(height: max(3, CGFloat(day.metrics.output) / CGFloat(maxOutput) * 72))
                    Text(String(day.day.suffix(2)))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 92)
    }
}

struct ActiveBlockStrip: View {
    let block: ActiveBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Claude block")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                if let remaining = block.remainingMinutes {
                    Stat(label: "Remaining", value: "\(remaining)m")
                }
                if let burn = block.burnRateTokensPerMinute {
                    Stat(label: "Burn", value: "\(Int(burn))/m")
                }
                if let projected = block.projectedTokens {
                    Stat(label: "Projected", value: UsageFormatters.tokens(projected))
                }
                if let cost = block.projectedCost {
                    Stat(label: "Cost", value: UsageFormatters.cost(cost))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct Stat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UnavailableView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("ccusage unavailable")
                .font(.headline)
            Text("Install ccusage or check PATH")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Retry", action: retry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
