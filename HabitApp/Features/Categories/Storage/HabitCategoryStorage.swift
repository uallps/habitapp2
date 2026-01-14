#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import SwiftData

@MainActor
protocol HabitCategoryStorage {
    func category(for habitId: UUID) async throws -> HabitCategoryAssignment?
    func save(_ assignment: HabitCategoryAssignment) async throws
    func delete(for habitId: UUID) async throws
    func allAssignments() async throws -> [HabitCategoryAssignment]
    func habitIds(for category: HabitCategory) async throws -> Set<UUID>
}

@MainActor
final class HabitCategorySwiftDataStorage: HabitCategoryStorage {
    private var context: ModelContext? { SwiftDataContext.shared }

    func category(for habitId: UUID) async throws -> HabitCategoryAssignment? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        return try context.fetch(descriptor).first
    }

    func save(_ assignment: HabitCategoryAssignment) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == assignment.habitId })
        if try context.fetch(descriptor).isEmpty {
            context.insert(assignment)
        }
        try context.save()
    }

    func delete(for habitId: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        let assignments = try context.fetch(descriptor)
        for assignment in assignments { context.delete(assignment) }
        if !assignments.isEmpty {
            try context.save()
        }
    }

    func allAssignments() async throws -> [HabitCategoryAssignment] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>()
        return try context.fetch(descriptor)
    }

    func habitIds(for category: HabitCategory) async throws -> Set<UUID> {
        guard let context else { return [] }
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.category.rawValue == categoryRaw }
        )
        let assignments = try context.fetch(descriptor)
        return Set(assignments.map { $0.habitId })
    }
}
#endif

