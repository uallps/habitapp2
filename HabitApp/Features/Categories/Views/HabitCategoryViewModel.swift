import Foundation
import Combine

@MainActor
final class HabitCategoryViewModel: ObservableObject {
    @Published var assignment: HabitCategoryAssignment?

    private let habit: Habit
    private let storage: HabitCategoryStorage

    init(habit: Habit, storage: HabitCategoryStorage = HabitCategorySwiftDataStorage()) {
        self.habit = habit
        self.storage = storage
        Task { await load() }
    }

    func load() async {
        do {
            assignment = try await storage.category(for: habit.id)
        } catch {
            print("Category load error: \(error)")
        }
    }

    func select(_ category: HabitCategory) {
        if assignment == nil {
            assignment = HabitCategoryAssignment(habitId: habit.id, category: category)
        } else {
            assignment?.category = category
        }
        Task { await persist() }
    }

    private func persist() async {
        guard let assignment else { return }
        do {
            try await storage.save(assignment)
        } catch {
            print("Category save error: \(error)")
        }
    }

    var currentCategory: HabitCategory? {
        assignment?.category
    }
}

