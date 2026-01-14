import Foundation

enum StatsDateFormatter {
    static func rangeText(for period: StatsPeriod, interval: DateInterval, calendar: Calendar) -> String {
        switch period {
        case .daily:
            return dayFormatter(calendar).string(from: interval.start)
        case .weekly:
            let startText = dayFormatter(calendar).string(from: interval.start)
            let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            let endText = dayFormatter(calendar).string(from: endDate)
            return "Semana \(startText)-\(endText)"
        case .monthly:
            return monthFormatter(calendar).string(from: interval.start)
        case .yearly:
            return yearFormatter(calendar).string(from: interval.start)
        }
    }

    private static func dayFormatter(_ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM"
        return formatter
    }

    private static func monthFormatter(_ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }

    private static func yearFormatter(_ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy"
        return formatter
    }
}

