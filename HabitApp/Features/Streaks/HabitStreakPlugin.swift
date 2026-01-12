import Foundation
import SwiftUI
import SwiftData

@MainActor
final class HabitStreakPlugin: DataPlugin, ViewPlugin, HabitEventPlugin {
    private let config: AppConfig
    private let calendar = Calendar.current

    init(config: AppConfig) {
        self.config = config
    }

    var models: [any PersistentModel.Type] { [HabitStreak.self] }
    var isEnabled: Bool { config.isPremium && config.enableStreaks }

    func willDeleteHabit(_ habit: Habit) async {
        guard isEnabled else { return }
        try? await HabitStreakSwiftDataStorage().delete(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    func habitDidUpdate(_ habit: Habit) async {
        guard isEnabled, habit.isCompletedToday else { return }
        do {
            let storage = HabitStreakSwiftDataStorage()
            let streak = try await storage.streak(for: habit.id)
            let now = Date()
            if let last = streak.lastCompletion {
                if calendar.isDate(now, inSameDayAs: last) {
                    return
                }
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(yesterday, inSameDayAs: last) {
                    streak.current += 1
                } else {
                    streak.current = 1
                }
            } else {
                streak.current = 1
            }
            streak.lastCompletion = now
            streak.best = max(streak.best, streak.current)
            try await storage.save(streak)
        } catch {
            print("Streak plugin error: \(error)")
        }
    }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        if isEnabled {
            HabitStreakRowView(viewModel: HabitStreakViewModel(habit: habit))
        }
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        if isEnabled {
            HabitStreakDetailView(viewModel: HabitStreakViewModel(habit: habit.wrappedValue))
        }
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Rachas", isOn: Binding(
                get: { self.config.enableStreaks },
                set: { self.config.enableStreaks = $0 }
            ))
            .disabled(!config.isPremium)
            if !config.isPremium {
                Text("Disponible solo en Premium")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
