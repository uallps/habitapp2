import SwiftUI

struct RecapDetailScreen: View {
    @StateObject private var viewModel: RecapDetailViewModel
    private let calendar: Calendar
    @State private var selectedHabitId: UUID? = nil

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

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recap.highlights.prefix(3), id: \.self) { highlight in
                        HighlightRow(text: highlight)
                    }
                }
            } label: {
                Label("Highlights", systemImage: "sparkles")
            }

            streaksView(recap)

            mainVisualView(recap)

            if recap.expectedTotal > 0 {
                breakdownView(recap)
            }

            if recap.period == .yearly {
                annualStreaksView(recap)
            }

        }
    }

    @ViewBuilder
    private func headerView(for recap: StatsRecap) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(StatsDateFormatter.rangeText(for: recap.period, interval: recap.interval, calendar: calendar))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                statusPill(for: recap)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(rateText(for: recap))
                    .font(.largeTitle)
                    .bold()
                Spacer()
                completionChip(for: recap)
            }
            if let rate = recap.completionRate {
                ProgressView(value: rate)
                    .tint(statusColor(for: recap))
            }
        }
    }

    @ViewBuilder
    private func mainVisualView(_ recap: StatsRecap) -> some View {
        GroupBox {
            if recap.expectedTotal == 0 {
                Text("Sin habitos programados para este periodo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                switch recap.period {
                case .daily:
                    if let detail = dayDetail(for: recap) {
                        DayDetailView(detail: detail, calendar: calendar)
                            .id(detailRenderKey(for: detail))
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
                        if !recap.habitStats.isEmpty {
                            StatsHabitFilterView(
                                habits: recap.habitStats.map { stat in
                                    StatsHabitOption(
                                        id: stat.habitId,
                                        name: stat.name,
                                        isArchived: stat.isArchived
                                    )
                                },
                                selectedHabitId: $selectedHabitId
                            )
                        }
                        MonthlyCalendarView(
                            interval: recap.interval,
                            dayStats: calendarDayStats(for: recap),
                            selectedDate: $viewModel.selectedDate,
                            calendar: calendar
                        )
                        .id(monthlyCalendarRenderKey)
                        if let detail = dayDetail(for: recap) {
                            DayDetailView(detail: detail, calendar: calendar)
                                .id(detailRenderKey(for: detail))
                        }
                    }
                case .yearly:
                    ScrollView(.horizontal, showsIndicators: false) {
                        BarChartView(entries: monthEntries(from: recap))
                            .padding(.vertical, 8)
                    }
                }
            }
        } label: {
            Label("Visual principal", systemImage: "chart.xyaxis.line")
        }
    }

    @ViewBuilder
    private func streaksView(_ recap: StatsRecap) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                StatRow(
                    title: "Racha perfecta actual",
                    value: "\(recap.currentStreak) dias",
                    systemImage: "flame.fill",
                    tint: .orange
                )
                StatRow(
                    title: "Mejor racha perfecta",
                    value: "\(recap.bestStreak) dias",
                    systemImage: "star.fill",
                    tint: .yellow
                )
            }
        } label: {
            Label("Racha perfecta (global)", systemImage: "flame.fill")
        }
    }

    @ViewBuilder
    private func breakdownView(_ recap: StatsRecap) -> some View {
        GroupBox {
            VStack(spacing: 10) {
                ForEach(recap.habitStats) { stat in
                    HabitBreakdownRowView(stat: stat)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        } label: {
            Label("Breakdown por habito", systemImage: "list.bullet")
        }
    }

    @ViewBuilder
    private func annualStreaksView(_ recap: StatsRecap) -> some View {
        GroupBox {
            if recap.annualTopStreaks.isEmpty {
                Text("Sin rachas registradas para este año")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(recap.annualTopStreaks) { streak in
                        streakRow(streak)
                    }
                }
            }
        } label: {
            Label("Mejores rachas del año", systemImage: "crown.fill")
        }
    }

    private func rateText(for recap: StatsRecap) -> String {
        guard let rate = recap.completionRate else { return "-" }
        return String(format: "%.0f%%", rate * 100)
    }

    private func statusLabel(for recap: StatsRecap) -> String {
        recap.period.isCurrent(interval: recap.interval, calendar: calendar, relativeTo: Date()) ? "En curso" : "Finalizado"
    }

    private func statusColor(for recap: StatsRecap) -> Color {
        recap.period.isCurrent(interval: recap.interval, calendar: calendar, relativeTo: Date()) ? .green : .secondary
    }

    @ViewBuilder
    private func statusPill(for recap: StatsRecap) -> some View {
        Text(statusLabel(for: recap))
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: recap).opacity(0.15), in: Capsule())
            .foregroundColor(statusColor(for: recap))
    }

    @ViewBuilder
    private func completionChip(for recap: StatsRecap) -> some View {
        Text("\(recap.completedTotal)/\(recap.expectedTotal)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .foregroundColor(.secondary)
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

    private func dayDetail(for recap: StatsRecap) -> StatsDayDetail? {
        let day = calendar.startOfDay(for: viewModel.selectedDate)
        guard let dayStat = recap.dayStats.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) else {
            return nil
        }
        let statuses = recap.dayHabitStatuses[calendar.startOfDay(for: day)] ?? []
        if let habitId = selectedHabitId {
            let filtered = statuses.filter { $0.habitId == habitId }
            guard !filtered.isEmpty else { return nil }
            let completed = filtered.map(\.completed).reduce(0, +)
            let expected = filtered.map(\.expected).reduce(0, +)
            return StatsDayDetail(date: day, completed: completed, expected: expected, habits: filtered)
        }
        return StatsDayDetail(date: day, completed: dayStat.completed, expected: dayStat.expected, habits: statuses)
    }

    private func calendarDayStats(for recap: StatsRecap) -> [StatsDayStat] {
        guard let habitId = selectedHabitId else {
            return recap.dayStats
        }
        return recap.dayStats.map { stat in
            let day = calendar.startOfDay(for: stat.date)
            let statuses = recap.dayHabitStatuses[day] ?? []
            if let status = statuses.first(where: { $0.habitId == habitId }) {
                return StatsDayStat(date: stat.date, completed: status.completed, expected: status.expected)
            }
            return StatsDayStat(date: stat.date, completed: 0, expected: 0)
        }
    }

    private var monthlyCalendarRenderKey: String {
        let monthKey = String(Int(recapMonthAnchor.timeIntervalSince1970))
        let habitKey = selectedHabitId?.uuidString ?? "all"
        return "\(monthKey)-\(habitKey)"
    }

    private var recapMonthAnchor: Date {
        calendar.dateInterval(of: .month, for: viewModel.selectedDate)?.start ?? viewModel.selectedDate
    }

    private func detailRenderKey(for detail: StatsDayDetail) -> String {
        let dayKey = String(Int(detail.date.timeIntervalSince1970))
        let habitKey = selectedHabitId?.uuidString ?? "all"
        return "\(dayKey)-\(habitKey)"
    }

    @ViewBuilder
    private func streakRow(_ streak: StatsStreakSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(streak.habitName)
                .font(.subheadline)
            Text("Duracion: \(streak.lengthDays) dias")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(streakRangeLabel(streak))
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(streakMessage(for: streak.lengthDays, isActive: streak.isActive))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }

    private func streakRangeLabel(_ streak: StatsStreakSummary) -> String {
        let startText = shortDate(streak.startDate)
        let endText = streak.isActive ? "hoy" : shortDate(streak.endDate)
        return "Del \(startText) al \(endText)"
    }

    private func streakMessage(for lengthDays: Int, isActive: Bool) -> String {
        let base: String
        switch lengthDays {
        case 90...:
            base = "Impresionante constancia"
        case 60..<90:
            base = "Ritmo enorme, sigue asi"
        case 30..<60:
            base = "Muy buena racha"
        case 14..<30:
            base = "Buen avance"
        default:
            base = "Buen comienzo"
        }
        return isActive ? "\(base). Racha activa." : base
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

private struct HighlightRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatRow: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(tint)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

