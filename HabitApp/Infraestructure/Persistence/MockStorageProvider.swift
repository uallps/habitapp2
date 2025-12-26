@MainActor
final class MockStorageProvider: StorageProvider {
    private var storedHabits: [Habit]

    init(initialHabits: [Habit]? = nil) {
        self.storedHabits = initialHabits ?? HabitSamples.defaults
    }

    func loadHabits() async throws -> [Habit] {
        storedHabits
    }

    func saveHabits(_ habits: [Habit]) async throws {
        storedHabits = habits
    }
}
