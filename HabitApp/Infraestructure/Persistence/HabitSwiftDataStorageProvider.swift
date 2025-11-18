import Foundation
import SwiftData

final class SwiftDataContext {
    static var shared: ModelContext?
}

final class HabitSwiftDataStorageProvider: StorageProvider {
    private let modelContainer: ModelContainer
    private let context: ModelContext

    init(schema: Schema) {
        do {
            self.modelContainer = try ModelContainer(for: schema)
            self.context = ModelContext(modelContainer)
            SwiftDataContext.shared = context
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    func loadHabits() async throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }

    func saveHabits(_ habits: [Habit]) async throws {
        let existing = try await loadHabits()
        let existingIds = Set(existing.map { $0.id })
        let newIds = Set(habits.map { $0.id })

        for habit in existing where !newIds.contains(habit.id) {
            context.delete(habit)
        }

        for habit in habits where !existingIds.contains(habit.id) {
            context.insert(habit)
        }

        try context.save()
    }
}
