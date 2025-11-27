import Foundation
import SwiftData

protocol HabitStreakStorage {
    func streak(for habitId: UUID) async throws -> HabitStreak
    func save(_ streak: HabitStreak) async throws
    func delete(for habitId: UUID) async throws
}

final class HabitStreakSwiftDataStorage: HabitStreakStorage {
    private var context: ModelContext? { SwiftDataContext.shared }

    func streak(for habitId: UUID) async throws -> HabitStreak {
        if let context {
            let descriptor = FetchDescriptor<HabitStreak>(predicate: #Predicate { $0.habitId == habitId })
            if let streak = try context.fetch(descriptor).first {
                return streak
            }
            let fresh = HabitStreak(habitId: habitId)
            context.insert(fresh)
            try context.save()
            return fresh
        } else {
            return HabitStreak(habitId: habitId)
        }
    }

    func save(_ streak: HabitStreak) async throws {
        guard let context else { return }
        try context.save()
    }

    func delete(for habitId: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitStreak>(predicate: #Predicate { $0.habitId == habitId })
        let streaks = try context.fetch(descriptor)
        for streak in streaks {
            context.delete(streak)
        }
        if !streaks.isEmpty {
            try context.save()
        }
    }
}
