import SwiftUI

struct StatsQuickCalendarView: View {
    let recap: StatsRecap?
    let monthDate: Date
    let isLoading: Bool
    let calendar: Calendar
    @Binding var selectedDate: Date
    let onMoveMonth: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    onMoveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    onMoveMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }

            if isLoading {
                ProgressView()
            } else if let recap {
                MonthlyCalendarPreviewView(
                    interval: recap.interval,
                    dayStats: recap.dayStats,
                    calendar: calendar,
                    selectedDate: $selectedDate
                )

                if let detail = dayDetail(from: recap) {
                    DayDetailView(detail: detail, calendar: calendar)
                }
            } else {
                Text("Sin datos para mostrar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthDate)
    }

    private func dayDetail(from recap: StatsRecap) -> StatsDayDetail? {
        let day = calendar.startOfDay(for: selectedDate)
        guard let dayStat = recap.dayStats.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) else {
            return nil
        }
        let statuses = recap.dayHabitStatuses[calendar.startOfDay(for: day)] ?? []
        return StatsDayDetail(date: day, completed: dayStat.completed, expected: dayStat.expected, habits: statuses)
    }
}

private struct MonthlyCalendarPreviewView: View {
    let interval: DateInterval
    let dayStats: [StatsDayStat]
    let calendar: Calendar
    @Binding var selectedDate: Date

    private var dayLookup: [Date: StatsDayStat] {
        Dictionary(uniqueKeysWithValues: dayStats.map { (calendar.startOfDay(for: $0.date), $0) })
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(daysForGrid(), id: \.self) { date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let index = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[index...] + symbols[..<index])
    }

    private func daysForGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: interval.start),
              let range = calendar.range(of: .day, in: .month, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: leading))

        for offset in range {
            if let date = calendar.date(byAdding: .day, value: offset - 1, to: monthInterval.start) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let stat = dayLookup[day]
        let isSelected = calendar.isDate(selectedDate, inSameDayAs: day)
        Button {
            selectedDate = day
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .font(.caption)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(backgroundColor(for: stat))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func backgroundColor(for stat: StatsDayStat?) -> Color {
        guard let stat else {
            return Color.clear
        }
        if stat.expected == 0 {
            return Color.gray.opacity(0.15)
        }
        if stat.completed == 0 {
            return Color.red.opacity(0.2)
        }
        if stat.completed == stat.expected {
            return Color.green.opacity(0.25)
        }
        return Color.orange.opacity(0.25)
    }
}
