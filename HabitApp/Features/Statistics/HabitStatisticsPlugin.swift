import Foundation
import SwiftData
import SwiftUI

@MainActor
final class HabitStatisticsPlugin: ViewPlugin, TabPlugin, DataPlugin, HabitEventPlugin {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    var models: [any PersistentModel.Type] { [] }
    var isEnabled: Bool { config.isPremium && config.enableStatistics }

    func willDeleteHabit(_ habit: Habit) async {
        guard isEnabled else { return }
        do {
            try await config.statisticsDependencies.completionDataSource.deleteCompletions(for: habit.id)
        } catch {
            print("Stats delete error: \(error)")
        }
    }

    func didDeleteHabit(habitId: UUID) async { }

    func habitDidUpdate(_ habit: Habit) async {
        guard isEnabled else { return }
        let calendar = config.statisticsDependencies.calendar
        let completionSource = config.statisticsDependencies.completionDataSource
        if habit.isCompletedToday {
            let date = habit.lastCompletionDate ?? Date()
            do {
                try await completionSource.recordCompletion(habitId: habit.id, date: date)
            } catch {
                print("Stats completion error: \(error)")
            }
        } else if let last = habit.lastCompletionDate, calendar.isDateInToday(last) {
            do {
                try await completionSource.removeCompletion(habitId: habit.id, date: last)
            } catch {
                print("Stats completion remove error: \(error)")
            }
        }
    }

    func tabItem() -> PluginTabItem? {
        guard isEnabled else { return nil }
        let overview = StatsOverviewScreen(dependencies: config.statisticsDependencies)
        return PluginTabItem(
            id: "statistics",
            title: "Estadisticas",
            systemImage: "chart.bar.xaxis",
            view: AnyView(overview),
            order: 40
        )
    }

    @MainActor
    @ViewBuilder
    func habitRowView(for habit: Habit) -> some View {
        HabitStreakRowView(habit: habit, dependencies: config.statisticsDependencies)
    }

    @MainActor
    @ViewBuilder
    func habitDetailView(for habit: Binding<Habit>) -> some View {
        HabitStreakDetailSummaryView(habit: habit.wrappedValue, dependencies: config.statisticsDependencies)
    }

    @MainActor
    @ViewBuilder
    func settingsView() -> some View {
        HabitStatisticsSettingsView()
    }
}
