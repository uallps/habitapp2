import Foundation

@MainActor
final class HabitStreakSummaryViewModel: ObservableObject {
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0

    private let dependencies: StatisticsDependencies
    private let calculator: StatsCalculator
    private var habitSnapshot: StatsHabitSnapshot
    private var loadTask: Task<Void, Never>?

    init(habit: Habit, dependencies: StatisticsDependencies) {
        self.dependencies = dependencies
        self.calculator = StatsCalculator(calendar: dependencies.calendar)
        self.habitSnapshot = HabitStreakSummaryViewModel.snapshot(from: habit)
        refresh(from: habit)
    }

    func refresh(from habit: Habit) {
        habitSnapshot = HabitStreakSummaryViewModel.snapshot(from: habit)
        loadTask?.cancel()
        loadTask = Task { await load() }
    }

    private func load() async {
        let calendar = dependencies.calendar
        let endDay = calendar.startOfDay(for: Date())
        guard let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) else { return }
        let startDay = calendar.startOfDay(for: habitSnapshot.createdAt)
        let interval = DateInterval(start: startDay, end: endExclusive)

        do {
            let completions = try await dependencies.completionDataSource.completions(in: interval)
            if Task.isCancelled { return }
            let filtered = completions.filter { $0.habitId == habitSnapshot.id }
            let completionMap = calculator.completionMap(from: filtered)
            let streaks = calculator.habitStreak(for: habitSnapshot, completionMap: completionMap, through: endDay)
            currentStreak = streaks.current
            bestStreak = streaks.best
        } catch {
            currentStreak = 0
            bestStreak = 0
        }
    }

    private static func snapshot(from habit: Habit) -> StatsHabitSnapshot {
        StatsHabitSnapshot(
            id: habit.id,
            name: habit.name,
            frequency: habit.frequency == .daily ? .daily : .weekly,
            createdAt: habit.createdAt,
            weeklyDays: habit.weeklyDays,
            archivedAt: habit.archivedAt
        )
    }
}
