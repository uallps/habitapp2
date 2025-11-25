import Foundation
import SwiftData

protocol HabitReminderStorage {
    func reminder(for habitId: UUID) async throws -> HabitReminder?
    func save(_ reminder: HabitReminder) async throws
    func delete(for habitId: UUID) async throws
}

final class HabitReminderSwiftDataStorage: HabitReminderStorage {
    private var context: ModelContext? {
        SwiftDataContext.shared
    }

    func reminder(for habitId: UUID) async throws -> HabitReminder? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<HabitReminder>(predicate: #Predicate { $0.habitId == habitId })
        return try context.fetch(descriptor).first
    }

    func save(_ reminder: HabitReminder) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitReminder>(predicate: #Predicate { $0.habitId == reminder.habitId })
        let existing = try context.fetch(descriptor)
        if existing.isEmpty {
            context.insert(reminder)
        }
        try context.save()
    }

    func delete(for habitId: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitReminder>(predicate: #Predicate { $0.habitId == habitId })
        let reminders = try context.fetch(descriptor)
        for reminder in reminders {
            context.delete(reminder)
        }
        if !reminders.isEmpty {
            try context.save()
        }
    }
}
