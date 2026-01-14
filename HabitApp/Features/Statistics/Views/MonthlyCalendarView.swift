#if PREMIUM || PLUGIN_STATS
import SwiftUI

struct MonthlyCalendarView: View {
    let interval: DateInterval
    let dayStats: [StatsDayStat]
    @Binding var selectedDate: Date
    let calendar: Calendar

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

#endif
