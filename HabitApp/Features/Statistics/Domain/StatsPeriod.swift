import Foundation

enum StatsPeriod: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Diario"
        case .weekly: return "Semanal"
        case .monthly: return "Mensual"
        case .yearly: return "Anual"
        }
    }

    var shortTitle: String { title }

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }

    func interval(containing date: Date, calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: calendarComponent, for: date) ?? DateInterval(start: date, end: date)
    }

    func previousInterval(from referenceDate: Date, calendar: Calendar) -> DateInterval {
        let current = interval(containing: referenceDate, calendar: calendar)
        let offset = calendar.date(byAdding: calendarComponent, value: -1, to: current.start) ?? referenceDate
        return interval(containing: offset, calendar: calendar)
    }
}
