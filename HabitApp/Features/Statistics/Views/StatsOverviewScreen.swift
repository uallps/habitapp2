import SwiftUI

struct StatsOverviewScreen: View {
    @StateObject private var viewModel: StatsOverviewViewModel
    private let dependencies: StatisticsDependencies

    init(dependencies: StatisticsDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: StatsOverviewViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
            }
            .navigationTitle("Estadisticas")
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.referenceDate) { _, _ in
                Task { await viewModel.refresh() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Cargando estadisticas")
                .frame(maxWidth: .infinity, alignment: .center)
        case .empty(let message):
            EmptyStatsView(message: message)
        case .error(let message):
            Text(message)
                .foregroundColor(.secondary)
        case .loaded(let payload):
            loadedContent(payload)
        }
    }

    @ViewBuilder
    private func loadedContent(_ payload: StatsOverviewContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Fecha de referencia") {
                DatePicker("Fecha", selection: $viewModel.referenceDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            if let summaryRecap = payload.recaps[viewModel.summaryPeriod] {
                GroupBox("Resumen") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Periodo", selection: $viewModel.summaryPeriod) {
                            ForEach(StatsPeriod.allCases) { period in
                                Text(period.title).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)

                        StatsSummaryCard(recap: summaryRecap)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Recaps")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(StatsPeriod.allCases) { period in
                        if let recap = payload.recaps[period] {
                            NavigationLink {
                                RecapDetailScreen(
                                    period: period,
                                    referenceDate: viewModel.referenceDate,
                                    dependencies: dependencies
                                )
                            } label: {
                                RecapCardView(recap: recap, calendar: dependencies.calendar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let summaryRecap = payload.recaps[viewModel.summaryPeriod] {
                GroupBox("Vista rapida") {
                    if summaryRecap.expectedTotal == 0 {
                        Text("Sin habitos programados para este periodo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        MiniChartView(entries: miniChartEntries(for: summaryRecap), period: summaryRecap.period)
                    }
                }
            }
        }
    }

    private func miniChartEntries(for recap: StatsRecap) -> [BarEntry] {
        switch recap.period {
        case .daily:
            return recap.habitStats
                .filter { $0.expected > 0 }
                .prefix(5)
                .map { stat in
                    BarEntry(label: shortLabel(stat.name), completed: stat.completed, expected: stat.expected)
                }
        case .weekly:
            return recap.dayStats.map { stat in
                let weekday = dependencies.calendar.component(.weekday, from: stat.date)
                let label = dependencies.calendar.shortWeekdaySymbols[weekday - 1]
                return BarEntry(label: label, completed: stat.completed, expected: stat.expected)
            }
        case .monthly:
            return recap.dayStats.map { stat in
                let label = String(dependencies.calendar.component(.day, from: stat.date))
                return BarEntry(label: label, completed: stat.completed, expected: stat.expected)
            }
        case .yearly:
            let grouped = Dictionary(grouping: recap.dayStats) { stat in
                dependencies.calendar.component(.month, from: stat.date)
            }
            return (1...12).map { month in
                let stats = grouped[month] ?? []
                let completed = stats.map(\.completed).reduce(0, +)
                let expected = stats.map(\.expected).reduce(0, +)
                let label = dependencies.calendar.shortMonthSymbols[month - 1]
                return BarEntry(label: label, completed: completed, expected: expected)
            }
        }
    }

    private func shortLabel(_ text: String) -> String {
        if text.count <= 4 { return text }
        let index = text.index(text.startIndex, offsetBy: 4)
        return String(text[..<index])
    }
}

private struct StatsSummaryCard: View {
    let recap: StatsRecap

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Completados")
                Spacer()
                Text("\(recap.completedTotal)/\(recap.expectedTotal)")
            }
            HStack {
                Text("Cumplimiento")
                Spacer()
                Text(rateText)
            }
            HStack {
                Text("Racha actual")
                Spacer()
                Text("\(recap.currentStreak) dias")
            }
        }
        .font(.subheadline)
    }

    private var rateText: String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }
}

private struct RecapCardView: View {
    let recap: StatsRecap
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recap.period.title)
                .font(.headline)
            Text(StatsDateFormatter.rangeText(for: recap.period, interval: recap.interval, calendar: calendar))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(rateText)
                .font(.title3)
                .bold()
            Text("\(recap.completedTotal)/\(recap.expectedTotal)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(recap.primaryHighlight)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    private var rateText: String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }
}

private struct MiniChartView: View {
    let entries: [BarEntry]
    let period: StatsPeriod

    var body: some View {
        if entries.isEmpty {
            Text("Sin datos para mostrar")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                BarChartView(entries: entries)
                    .padding(.vertical, 8)
            }
        }
    }
}

private struct EmptyStatsView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.headline)
            Text("Crear habito")
                .font(.headline)
                .foregroundColor(.accentColor)
            Text("Usa la pestaña Habitos para agregar el primero.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }
}
