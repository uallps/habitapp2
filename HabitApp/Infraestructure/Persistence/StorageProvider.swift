@MainActor
protocol StorageProvider {
    func loadHabits() async throws -> [Habit]
    func saveHabits(_ habits: [Habit]) async throws
}
