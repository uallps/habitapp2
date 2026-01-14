import Foundation

struct StatsHighlightBuilder {
    func highlights(
        period: StatsPeriod,
        isCurrent: Bool,
        completed: Int,
        expected: Int,
        completionRate: Double?,
        bestWeekday: String?,
        topHabit: String?,
        bestMonthName: String?,
        worstMonthName: String?
    ) -> [String] {
        var items: [String] = []
        let primary = primaryHighlight(
            period: period,
            isCurrent: isCurrent,
            completed: completed,
            expected: expected,
            completionRate: completionRate,
            bestWeekday: bestWeekday,
            topHabit: topHabit
        )
        items.append(primary)

        if expected > 0 {
            if period == .yearly, let bestMonthName {
                let worstPart = worstMonthName.map { " - Peor mes: \($0)" } ?? ""
                let message = "Mejor mes: \(bestMonthName)\(worstPart)"
                if !items.contains(message) {
                    items.append(message)
                }
            }

            if let weekday = bestWeekday {
                let message = "Tu mejor dia fue: \(weekday)"
                if !items.contains(message) {
                    items.append(message)
                }
            }

            if let habit = topHabit {
                let message = "Habito MVP: \(habit)"
                if !items.contains(message) {
                    items.append(message)
                }
            }
        }

        return Array(items.prefix(3))
    }

    private func primaryHighlight(
        period: StatsPeriod,
        isCurrent: Bool,
        completed: Int,
        expected: Int,
        completionRate: Double?,
        bestWeekday: String?,
        topHabit: String?
    ) -> String {
        if expected == 0 {
            return "Sin habitos programados para este periodo"
        }

        let rate = completionRate ?? 0
        if isCurrent {
            return currentPeriodHighlight(period: period, rate: rate, completed: completed, expected: expected)
        }

        if completed == expected, expected > 0 {
            return pastPeriodHighlight(period: period, type: .perfect)
        }
        if rate >= 0.8, expected > 0 {
            return pastPeriodHighlight(period: period, type: .good)
        }
        if rate > 0, rate < 0.5 {
            return pastPeriodHighlight(period: period, type: .low)
        }
        if rate == 0, expected > 0 {
            return "Sin completados en este periodo"
        }

        if let weekday = bestWeekday {
            return "Tu mejor dia fue: \(weekday)"
        }
        if let habit = topHabit {
            return "Habito MVP: \(habit)"
        }
        return "Sin datos aplicables para este periodo"
    }

    private func currentPeriodHighlight(period: StatsPeriod, rate: Double, completed: Int, expected: Int) -> String {
        if completed == expected, expected > 0 {
            switch period {
            case .daily:
                return "En curso: perfecto hoy"
            case .weekly:
                return "En curso: semana perfecta hasta hoy"
            case .monthly:
                return "En curso: mes perfecto hasta hoy"
            case .yearly:
                return "En curso: año perfecto hasta hoy"
            }
        }
        if rate == 0, expected > 0 {
            return "En curso: aun sin completados"
        }
        if rate >= 0.8 {
            switch period {
            case .daily:
                return "En curso: muy bien hoy"
            case .weekly:
                return "En curso: vas bien esta semana"
            case .monthly:
                return "En curso: buen ritmo este mes"
            case .yearly:
                return "En curso: buen ritmo este año"
            }
        }
        if rate > 0, rate < 0.5 {
            switch period {
            case .daily:
                return "En curso: hoy flojo, aun puedes"
            case .weekly:
                return "En curso: semana floja, aun puedes remontar"
            case .monthly:
                return "En curso: mes flojo, aun hay tiempo"
            case .yearly:
                return "En curso: año flojo, aun hay tiempo"
            }
        }
        switch period {
        case .daily:
            return "En curso: buen ritmo hoy"
        case .weekly:
            return "En curso: buen ritmo esta semana"
        case .monthly:
            return "En curso: ritmo estable este mes"
        case .yearly:
            return "En curso: ritmo estable este año"
        }
    }

    private func pastPeriodHighlight(period: StatsPeriod, type: PastHighlightType) -> String {
        switch period {
        case .daily:
            return type == .perfect ? "Dia perfecto" : type == .good ? "Buen dia" : "Dia flojo"
        case .weekly:
            return type == .perfect ? "Semana perfecta" : type == .good ? "Muy buena semana" : "Semana floja"
        case .monthly:
            return type == .perfect ? "Mes perfecto" : type == .good ? "Buen mes" : "Mes flojo"
        case .yearly:
            return type == .perfect ? "Año perfecto" : type == .good ? "Buen año" : "Año flojo"
        }
    }
}

private enum PastHighlightType {
    case perfect
    case good
    case low
}

