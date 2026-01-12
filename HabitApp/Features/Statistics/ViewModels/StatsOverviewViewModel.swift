import Foundation

@MainActor
final class StatsOverviewViewModel: ObservableObject {
    @Published var referenceDate: Date
    @Published var summaryPeriod: StatsPeriod
    @Published private(set) var state: StatsLoadState<StatsOverviewContent> = .loading

    private let dependencies: StatisticsDependencies
    private let calculator: StatsCalculator
    private var recapCache: [Date: [StatsPeriod: StatsRecap]] = [:]

    init(dependencies: StatisticsDependencies, referenceDate: Date = Date()) {
        self.dependencies = dependencies
        self.referenceDate = referenceDate
        self.summaryPeriod = .weekly
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
            return
        }

        do {
            let habits = try await dependencies.habitDataSource.fetchHabits()
            if habits.isEmpty {
                state = .empty("No hay habitos activos")
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
        } catch {
            state = .error("No se pudieron cargar las estadisticas")
        }
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
}

struct StatsOverviewContent {
    let recaps: [StatsPeriod: StatsRecap]
}
