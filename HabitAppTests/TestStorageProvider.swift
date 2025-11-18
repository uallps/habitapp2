import Foundation
@testable import HabitApp

actor SpyStorageProvider: StorageProvider {
    private var storedHabits: [Habit]
    private var saveCallCount = 0

    init(initialHabits: [Habit]) {
        self.storedHabits = initialHabits
    }

    func loadHabits() async throws -> [Habit] {
        storedHabits
    }

    func saveHabits(_ habits: [Habit]) async throws {
        saveCallCount += 1
        storedHabits = habits
    }

    func savedHabitsSnapshot() async -> [Habit] {
        storedHabits
    }

    func saveCalls() async -> Int {
        saveCallCount
    }
}
