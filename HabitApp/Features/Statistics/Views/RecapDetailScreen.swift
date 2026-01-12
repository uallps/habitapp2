import SwiftUI

struct RecapDetailScreen: View {
    @StateObject private var viewModel: RecapDetailViewModel
    private let calendar: Calendar

    init(period: StatsPeriod, referenceDate: Date, dependencies: StatisticsDependencies) {
        self.calendar = dependencies.calendar
        _viewModel = StateObject(
            wrappedValue: RecapDetailViewModel(
                period: period,
                referenceDate: referenceDate,
                dependencies: dependencies
            )
        )
    }

    var body: some View {
        ScrollView {
            content
                .padding()
        }
        .navigationTitle("Recap \(viewModel.period.title)")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Cargando recap")
                .frame(maxWidth: .infinity, alignment: .center)
        case .empty(let message):
            Text(message)
                .foregroundColor(.secondary)
        case .error(let message):
            Text(message)
                .foregroundColor(.secondary)
        case .loaded(let recap):
            recapContent(recap)
        }
    }

    @ViewBuilder
    private func recapContent(_ recap: StatsRecap) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView(for: recap)

            VStack(alignment: .leading, spacing: 8) {
                Text("Highlights")
                    .font(.headline)
                ForEach(recap.highlights.prefix(3), id: \.self) { highlight in
                    Text(highlight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            summaryMetricsView(recap)

            mainVisualView(recap)

            if recap.expectedTotal > 0 {
                breakdownView(recap)
            }

            if let comparison = recap.comparison {
                comparisonView(comparison)
            }
        }
    }

    @ViewBuilder
    private func headerView(for recap: StatsRecap) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(StatsDateFormatter.rangeText(for: recap.period, interval: recap.interval, calendar: calendar))
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text(rateText(for: recap))
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Text("\(recap.completedTotal)/\(recap.expectedTotal)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func summaryMetricsView(_ recap: StatsRecap) -> some View {
        GroupBox("Resumen") {
            HStack {
                VStack(alignment: .leading) {
                    Text("Activos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(recap.activeHabitsCount)")
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Con avances")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(recap.habitsWithCompletionCount)")
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Nunca completados")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(recap.habitsNeverCompletedCount)")
                }
            }
        }
    }

    @ViewBuilder
    private func mainVisualView(_ recap: StatsRecap) -> some View {
        GroupBox("Visual principal") {
            if recap.expectedTotal == 0 {
                Text("Sin habitos programados para este periodo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                switch recap.period {
                case .daily:
                    if let detail = viewModel.selectedDayDetail {
                        DayDetailView(detail: detail, calendar: calendar)
                    } else {
                        Text("Sin habitos programados")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .weekly:
                    ScrollView(.horizontal, showsIndicators: false) {
                        BarChartView(entries: dayEntries(from: recap, useWeekday: true))
                            .padding(.vertical, 8)
                    }
                case .monthly:
                    VStack(alignment: .leading, spacing: 12) {
                        MonthlyCalendarView(
                            interval: recap.interval,
                            dayStats: recap.dayStats,
                            selectedDate: $viewModel.selectedDate,
                            calendar: calendar
                        )
                        if let detail = viewModel.selectedDayDetail {
                            DayDetailView(detail: detail, calendar: calendar)
                        }
                    }
                case .yearly:
                    ScrollView(.horizontal, showsIndicators: false) {
                        BarChartView(entries: monthEntries(from: recap))
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func breakdownView(_ recap: StatsRecap) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breakdown por habito")
                .font(.headline)
            VStack(spacing: 10) {
                ForEach(recap.habitStats) { stat in
                    HabitBreakdownRowView(stat: stat)
                }
            }
        }
    }

    @ViewBuilder
    private func comparisonView(_ comparison: StatsComparison) -> some View {
        GroupBox("Comparacion con periodo anterior") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Delta cumplimiento: \(String(format: "%.0f%%", comparison.deltaRate * 100))")
                Text("Delta completados: \(comparison.deltaCompleted)")
                Text("Tendencia: \(comparison.trendLabel)")
            }
            .font(.subheadline)
        }
    }

    private func rateText(for recap: StatsRecap) -> String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }

    private func dayEntries(from recap: StatsRecap, useWeekday: Bool) -> [BarEntry] {
        recap.dayStats.map { stat in
            let label: String
            if useWeekday {
                let weekday = calendar.component(.weekday, from: stat.date)
                label = calendar.shortWeekdaySymbols[weekday - 1]
            } else {
                label = String(calendar.component(.day, from: stat.date))
            }
            return BarEntry(label: label, completed: stat.completed, expected: stat.expected)
        }
    }

    private func monthEntries(from recap: StatsRecap) -> [BarEntry] {
        let grouped = Dictionary(grouping: recap.dayStats) { stat in
            calendar.component(.month, from: stat.date)
        }
        return (1...12).map { month in
            let stats = grouped[month] ?? []
            let completed = stats.map(\.completed).reduce(0, +)
            let expected = stats.map(\.expected).reduce(0, +)
            let label = calendar.shortMonthSymbols[month - 1]
            return BarEntry(label: label, completed: completed, expected: expected)
        }
    }
}
