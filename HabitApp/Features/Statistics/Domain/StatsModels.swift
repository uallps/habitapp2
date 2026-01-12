import Foundation

struct StatsDayStat: Identifiable {
    var id: Date { date }
    let date: Date
    let completed: Int
    let expected: Int
}

enum StatsHabitBadge: String {
    case top
    case risk
}

struct StatsHabitStat: Identifiable {
    var id: UUID { habitId }
    let habitId: UUID
    let name: String
    let completed: Int
    let expected: Int
    let rate: Double?
    let badge: StatsHabitBadge?
}

struct StatsHabitDayStatus: Identifiable {
    var id: UUID { habitId }
    let habitId: UUID
    let name: String
    let completed: Int
    let expected: Int
}

struct StatsComparison {
    let previousRate: Double
    let deltaRate: Double
    let deltaCompleted: Int
    let trendLabel: String
}

struct StatsRecap {
    let period: StatsPeriod
    let interval: DateInterval
    let completedTotal: Int
    let expectedTotal: Int
    let completionRate: Double?
    let activeHabitsCount: Int
    let habitsWithCompletionCount: Int
    let habitsNeverCompletedCount: Int
    let dayStats: [StatsDayStat]
    let habitStats: [StatsHabitStat]
    let dayHabitStatuses: [Date: [StatsHabitDayStatus]]
    let bestWeekday: String?
    let worstWeekday: String?
    let bestMonthName: String?
    let worstMonthName: String?
    let currentStreak: Int
    let bestStreak: Int
    let comparison: StatsComparison?
    let highlights: [String]
    let primaryHighlight: String
}
