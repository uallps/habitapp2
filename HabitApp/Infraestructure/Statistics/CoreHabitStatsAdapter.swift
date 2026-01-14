#if PREMIUM || PLUGIN_STATS
import Foundation

@MainActor
struct CoreHabitStatsAdapter: HabitStatsDataSource {
    let storageProvider: StorageProvider

    func fetchHabits() async throws -> [StatsHabitSnapshot] {
        let habits = try await storageProvider.loadHabits()
        return habits.map { habit in
            StatsHabitSnapshot(
                id: habit.id,
                name: habit.name,
                frequency: mapFrequency(habit.frequency),
                createdAt: habit.createdAt,
                weeklyDays: habit.weeklyDays,
                archivedAt: habit.archivedAt
            )
        }
    }

    private func mapFrequency(_ frequency: HabitFrequency) -> StatsHabitFrequency {
        switch frequency {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        }
    }
}

#endif
