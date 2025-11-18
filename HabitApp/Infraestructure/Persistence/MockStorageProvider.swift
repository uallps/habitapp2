final class MockStorageProvider: StorageProvider {
    private var storedHabits: [Habit]

    init(initialHabits: [Habit] = HabitSamples.defaults) {
        self.storedHabits = initialHabits
    }

    func loadHabits() async throws -> [Habit] {
        storedHabits
    }

    func saveHabits(_ habits: [Habit]) async throws {
        storedHabits = habits
    }
}
