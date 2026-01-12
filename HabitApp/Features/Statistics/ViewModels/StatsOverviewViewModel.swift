import Foundation
import Combine

@MainActor
final class StatsOverviewViewModel: ObservableObject {
    @Published var referenceDate: Date
    @Published var summaryPeriod: StatsPeriod
    @Published private(set) var state: StatsLoadState<StatsOverviewContent> = .loading
    @Published var quickViewMonth: Date
    @Published var quickViewSelectedDate: Date
    @Published private(set) var quickViewRecap: StatsRecap?
    @Published private(set) var isQuickViewLoading: Bool = false

    private let dependencies: StatisticsDependencies
    private let calculator: StatsCalculator
    private var recapCache: [Date: [StatsPeriod: StatsRecap]] = [:]
    private var cachedHabits: [StatsHabitSnapshot] = []

    init(dependencies: StatisticsDependencies, referenceDate: Date = Date()) {
        self.dependencies = dependencies
        self.referenceDate = dependencies.calendar.startOfDay(for: referenceDate)
        self.summaryPeriod = .weekly
        self.quickViewMonth = dependencies.calendar.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
        self.quickViewSelectedDate = dependencies.calendar.startOfDay(for: referenceDate)
        self.calculator = StatsCalculator(calendar: dependencies.calendar)
        Task { await load() }
    }

    func load() async {
        await refresh(usingCache: true)
    }

    func refresh() async {
        await refresh(usingCache: false)
    }

    private func refresh(usingCache: Bool) async {
        state = .loading
        let cacheKey = dependencies.calendar.startOfDay(for: referenceDate)
        if usingCache, let cached = recapCache[cacheKey] {
            state = makeState(from: cached)
            quickViewMonth = startOfMonth(for: referenceDate)
            quickViewSelectedDate = dependencies.calendar.startOfDay(for: referenceDate)
            quickViewRecap = cached[.monthly]
            return
        }

        do {
            let habits = try await dependencies.habitDataSource.fetchHabits()
            cachedHabits = habits
            if habits.isEmpty {
                state = .empty("No hay habitos activos")
                quickViewRecap = nil
                return
            }

            let overallInterval = overallInterval(for: referenceDate)
            let completions = try await dependencies.completionDataSource.completions(in: overallInterval)
            let completionMap = calculator.completionMap(from: completions)
            let referenceDate = referenceDate
            let periods = StatsPeriod.allCases
            let calculator = calculator
            let recaps = await Task.detached(priority: .userInitiated) {
                var results: [StatsPeriod: StatsRecap] = [:]
                for period in periods {
                    results[period] = calculator.recap(
                        period: period,
                        referenceDate: referenceDate,
                        habits: habits,
                        completionMap: completionMap
                    )
                }
                return results
            }.value

            recapCache[cacheKey] = recaps
            state = makeState(from: recaps)
            quickViewMonth = startOfMonth(for: referenceDate)
            quickViewSelectedDate = dependencies.calendar.startOfDay(for: referenceDate)
            quickViewRecap = recaps[.monthly]
        } catch {
            state = .error("No se pudieron cargar las estadisticas")
            quickViewRecap = nil
        }
    }

    func resetQuickView() {
        quickViewMonth = startOfMonth(for: referenceDate)
        quickViewSelectedDate = dependencies.calendar.startOfDay(for: referenceDate)
        Task { await loadQuickView(for: quickViewMonth) }
    }

    func setReferenceDateToToday() {
        let today = dependencies.calendar.startOfDay(for: Date())
        let current = dependencies.calendar.startOfDay(for: referenceDate)
        if current != today {
            referenceDate = today
        } else {
            resetQuickView()
        }
    }

    func moveQuickViewMonth(by offset: Int) {
        guard let newMonth = dependencies.calendar.date(byAdding: .month, value: offset, to: quickViewMonth) else { return }
        quickViewMonth = startOfMonth(for: newMonth)
        Task { await loadQuickView(for: quickViewMonth) }
    }

    private func loadQuickView(for monthDate: Date) async {
        isQuickViewLoading = true
        do {
            let habits = cachedHabits.isEmpty ? try await dependencies.habitDataSource.fetchHabits() : cachedHabits
            cachedHabits = habits
            let interval = StatsPeriod.monthly.interval(containing: monthDate, calendar: dependencies.calendar)
            let previous = StatsPeriod.monthly.previousInterval(from: monthDate, calendar: dependencies.calendar)
            let overall = DateInterval(start: previous.start, end: interval.end)
            let completions = try await dependencies.completionDataSource.completions(in: overall)
            let completionMap = calculator.completionMap(from: completions)
            let recap = calculator.recap(
                period: .monthly,
                referenceDate: monthDate,
                habits: habits,
                completionMap: completionMap
            )
            quickViewRecap = recap
        } catch {
            quickViewRecap = nil
        }
        isQuickViewLoading = false
    }

    private func makeState(from recaps: [StatsPeriod: StatsRecap]) -> StatsLoadState<StatsOverviewContent> {
        let activeCount = recaps[summaryPeriod]?.activeHabitsCount ?? 0
        if activeCount == 0 {
            return .empty("No hay habitos activos")
        }
        return .loaded(StatsOverviewContent(recaps: recaps))
    }

    private func overallInterval(for referenceDate: Date) -> DateInterval {
        var earliestStart = StatsPeriod.daily.interval(containing: referenceDate, calendar: dependencies.calendar).start
        var latestEnd = StatsPeriod.daily.interval(containing: referenceDate, calendar: dependencies.calendar).end

        for period in StatsPeriod.allCases {
            let current = period.interval(containing: referenceDate, calendar: dependencies.calendar)
            let previous = period.previousInterval(from: referenceDate, calendar: dependencies.calendar)
            earliestStart = min(earliestStart, previous.start)
            latestEnd = max(latestEnd, current.end)
        }
        return DateInterval(start: earliestStart, end: latestEnd)
    }

    private func startOfMonth(for date: Date) -> Date {
        dependencies.calendar.dateInterval(of: .month, for: date)?.start ?? date
    }
}

struct StatsOverviewContent {
    let recaps: [StatsPeriod: StatsRecap]
}
