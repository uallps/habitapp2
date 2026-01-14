#if PREMIUM || PLUGIN_STATS
import Foundation

enum StatsHabitFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
}

struct StatsHabitSnapshot: Identifiable, Hashable {
    let id: UUID
    let name: String
    let frequency: StatsHabitFrequency
    let createdAt: Date
    let weeklyDays: [Int]
    let archivedAt: Date?
}

struct StatsCompletionSnapshot: Hashable {
    let habitId: UUID
    let date: Date
    let count: Int
}

@MainActor
protocol HabitStatsDataSource {
    func fetchHabits() async throws -> [StatsHabitSnapshot]
}

@MainActor
protocol CompletionStatsDataSource {
    func completions(in interval: DateInterval) async throws -> [StatsCompletionSnapshot]
    func recordCompletion(habitId: UUID, date: Date) async throws
    func removeCompletion(habitId: UUID, date: Date) async throws
    func deleteCompletions(for habitId: UUID) async throws
}

struct StatisticsDependencies {
    let habitDataSource: HabitStatsDataSource
    let completionDataSource: CompletionStatsDataSource
    let calendar: Calendar
}

#endif
