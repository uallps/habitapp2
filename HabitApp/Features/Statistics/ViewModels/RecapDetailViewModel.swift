#if PREMIUM || PLUGIN_STATS
import Foundation
import Combine
@MainActor
final class RecapDetailViewModel: ObservableObject {
    @Published private(set) var state: StatsLoadState<StatsRecap> = .loading
    @Published var selectedDate: Date {
        didSet {
            if case let .loaded(recap) = state {
                updateSelectedDayDetail(from: recap)
            }
        }
    }
    @Published private(set) var selectedDayDetail: StatsDayDetail?

    let period: StatsPeriod
    private let dependencies: StatisticsDependencies
    private let calculator: StatsCalculator
    private let referenceDate: Date

    init(period: StatsPeriod, referenceDate: Date, dependencies: StatisticsDependencies) {
        self.period = period
        self.referenceDate = referenceDate
        self.dependencies = dependencies
        self.calculator = StatsCalculator(calendar: dependencies.calendar)
        self.selectedDate = referenceDate
        Task { await load() }
    }

    func load() async {
        state = .loading
        do {
            let habits = try await dependencies.habitDataSource.fetchHabits()
            let interval = period.interval(containing: referenceDate, calendar: dependencies.calendar)
            let previous = period.previousInterval(from: referenceDate, calendar: dependencies.calendar)
            let earliestHabit = habits.map(\.createdAt).min() ?? interval.start
            let overallStart = min(interval.start, min(previous.start, dependencies.calendar.startOfDay(for: earliestHabit)))
            let overallEnd = max(interval.end, previous.end)
            let overall = DateInterval(start: overallStart, end: overallEnd)
            let completions = try await dependencies.completionDataSource.completions(in: overall)
            let completionMap = calculator.completionMap(from: completions)
            let period = period
            let referenceDate = referenceDate
            let calculator = calculator
            let recap = await Task.detached(priority: .userInitiated) {
                calculator.recap(
                    period: period,
                    referenceDate: referenceDate,
                    habits: habits,
                    completionMap: completionMap
                )
            }.value
            state = .loaded(recap)
            updateSelectedDayDetail(from: recap)
        } catch {
            state = .error("No se pudieron cargar las estadisticas")
        }
    }

    private func updateSelectedDayDetail(from recap: StatsRecap) {
        let day = dependencies.calendar.startOfDay(for: selectedDate)
        guard let dayStat = recap.dayStats.first(where: { dependencies.calendar.isDate($0.date, inSameDayAs: day) }) else {
            selectedDayDetail = nil
            return
        }
        let statuses = recap.dayHabitStatuses[dependencies.calendar.startOfDay(for: day)] ?? []
        selectedDayDetail = StatsDayDetail(date: day, completed: dayStat.completed, expected: dayStat.expected, habits: statuses)
    }
}

struct StatsDayDetail {
    let date: Date
    let completed: Int
    let expected: Int
    let habits: [StatsHabitDayStatus]
}

#endif
