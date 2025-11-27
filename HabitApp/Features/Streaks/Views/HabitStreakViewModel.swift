import Foundation
import Combine

@MainActor
final class HabitStreakViewModel: ObservableObject {
    @Published private(set) var streak: HabitStreak

    private let habit: Habit
    private let storage: HabitStreakStorage

    init(habit: Habit, storage: HabitStreakStorage = HabitStreakSwiftDataStorage()) {
        self.habit = habit
        self.storage = storage
        self.streak = HabitStreak(habitId: habit.id)
        Task { await load() }
    }

    func load() async {
        do {
            streak = try await storage.streak(for: habit.id)
        } catch {
            print("Streak load error: \(error)")
        }
    }

    var summary: String {
        "Racha: \(streak.current) · Mejor: \(streak.best)"
    }
}

