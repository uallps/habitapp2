import Foundation
import Combine

@MainActor
final class HabitReminderViewModel: ObservableObject {
    @Published var reminder: HabitReminder?

    private let habit: Habit
    private let storage: HabitReminderStorage

    init(habit: Habit, storage: HabitReminderStorage = HabitReminderSwiftDataStorage()) {
        self.habit = habit
        self.storage = storage
        Task { await load() }
    }

    func load() async {
        do {
            if let existing = try await storage.reminder(for: habit.id) {
                reminder = existing
            } else {
                reminder = HabitReminder(habitId: habit.id)
            }
        } catch {
            print("Reminder load error: \(error)")
        }
    }

    func setEnabled(_ enabled: Bool) {
        if reminder == nil {
            reminder = HabitReminder(habitId: habit.id)
        }
        if enabled {
            if reminder?.reminderDate == nil {
                reminder?.reminderDate = Date()
            }
        } else {
            reminder?.reminderDate = nil
        }
        Task { await save() }
    }

    func update(date: Date) {
        if reminder == nil {
            reminder = HabitReminder(habitId: habit.id, reminderDate: date)
        } else {
            reminder?.reminderDate = date
        }
        Task { await save() }
    }

    private func save() async {
        guard let reminder else { return }
        do {
            try await storage.save(reminder)
        } catch {
            print("Reminder save error: \(error)")
        }
    }

    var hasReminder: Bool {
        reminder?.reminderDate != nil
    }

    var reminderDate: Date {
        reminder?.reminderDate ?? Date()
    }
}

