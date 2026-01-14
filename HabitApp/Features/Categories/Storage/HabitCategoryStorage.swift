import Foundation
import SwiftData

@MainActor
protocol HabitCategoryStorage {
    func category(for habitId: UUID) async throws -> HabitCategoryAssignment?
    func save(_ assignment: HabitCategoryAssignment) async throws
    func delete(for habitId: UUID) async throws
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
}

