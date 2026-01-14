#if PREMIUM || PLUGIN_STATS
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
    let isArchived: Bool
    let completed: Int
    let expected: Int
    let rate: Double?
    let badge: StatsHabitBadge?
    let currentStreak: Int
    let bestStreak: Int
}

struct StatsHabitDayStatus: Identifiable {
    var id: UUID { habitId }
    let habitId: UUID
    let name: String
    let completed: Int
    let expected: Int
}

struct StatsStreakSummary: Identifiable {
    var id: String { "\(habitId.uuidString)-\(startDate.timeIntervalSince1970)" }
    let habitId: UUID
    let habitName: String
    let startDate: Date
    let endDate: Date
    let lengthDays: Int
    let isActive: Bool
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
    let annualTopStreaks: [StatsStreakSummary]
    let highlights: [String]
    let primaryHighlight: String
}

#endif
