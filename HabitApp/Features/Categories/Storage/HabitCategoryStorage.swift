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
    var context: ModelContext? { SwiftDataContext.shared }

    func category(for habitId: UUID) async throws -> HabitCategoryAssignment? {
        guard let context = context else { return nil }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        let results = try context.fetch(descriptor)
        return results.first
    }

    func save(_ assignment: HabitCategoryAssignment) async throws {
        guard let context = context else { return }
        let habitId = assignment.habitId
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let existing = try context.fetch(descriptor)

        if let existingAssignment = existing.first {
            // Update existing record
            existingAssignment.categoryId = assignment.categoryId
            existingAssignment.legacyCategory = assignment.legacyCategory
        } else {
            // Insert new record
            context.insert(assignment)
        }
        try context.save()
    }

    func delete(for habitId: UUID) async throws {
        guard let context = context else { return }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        let assignments = try context.fetch(descriptor)
        for assignment in assignments { context.delete(assignment) }
        if !assignments.isEmpty {
            try context.save()
        }
    }

    func allAssignments() async throws -> [HabitCategoryAssignment] {
        guard let context = context else { return [] }
        let descriptor = FetchDescriptor<HabitCategoryAssignment>()
        return try context.fetch(descriptor)
    }

    func habitIds(for category: HabitCategory) async throws -> Set<UUID> {
        guard let context = context else { return [] }
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<HabitCategoryAssignment>(
            predicate: #Predicate { $0.legacyCategory == categoryRaw }
        )
        let assignments = try context.fetch(descriptor)
        return Set(assignments.map { $0.habitId })
    }
}
#endif
