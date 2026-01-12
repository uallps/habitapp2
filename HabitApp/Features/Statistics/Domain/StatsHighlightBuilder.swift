import Foundation

struct StatsHighlightBuilder {
    func highlights(
        completed: Int,
        expected: Int,
        completionRate: Double?,
        bestWeekday: String?,
        topHabit: String?
    ) -> [String] {
        var items: [String] = []
        let primary = primaryHighlight(
            completed: completed,
            expected: expected,
            completionRate: completionRate,
            bestWeekday: bestWeekday,
            topHabit: topHabit
        )
        items.append(primary)

        if expected > 0 {
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
        completed: Int,
        expected: Int,
        completionRate: Double?,
        bestWeekday: String?,
        topHabit: String?
    ) -> String {
        if expected == 0 {
            return "Sin habitos programados para este periodo"
        }
        if completed == expected, expected > 0 {
            return "Perfecto: completaste todo lo esperado"
        }
        if let rate = completionRate, rate >= 0.8, expected > 0 {
            return "Muy bien: gran constancia en este periodo"
        }
        if let rate = completionRate, rate > 0, rate < 0.5 {
            return "Toca retomar: poco cumplimiento este periodo"
        }
        if let weekday = bestWeekday {
            return "Tu mejor dia fue: \(weekday)"
        }
        if let habit = topHabit {
            return "Habito MVP: \(habit)"
        }
        return "Sin datos aplicables para este periodo"
    }
}
