#if PREMIUM || PLUGIN_STATS
import Foundation

final class StatsCalculator {
    private let calendar: Calendar
    private let highlightBuilder = StatsHighlightBuilder()

    init(calendar: Calendar) {
        self.calendar = calendar
    }

    func completionMap(from completions: [StatsCompletionSnapshot]) -> [UUID: [Date: Int]] {
        var map: [UUID: [Date: Int]] = [:]
        for completion in completions {
            let day = calendar.startOfDay(for: completion.date)
            var habitMap = map[completion.habitId, default: [:]]
            habitMap[day] = 1
            map[completion.habitId] = habitMap
        }
        return map
    }

    func recap(
        period: StatsPeriod,
        referenceDate: Date,
        habits: [StatsHabitSnapshot],
        completionMap: [UUID: [Date: Int]]
    ) -> StatsRecap {
        let interval = period.interval(containing: referenceDate, calendar: calendar)
        let metrics = buildMetrics(interval: interval, habits: habits, completionMap: completionMap)
        let isCurrentPeriod = period.isCurrent(interval: interval, calendar: calendar, relativeTo: Date())
        let highlightMetrics = highlightMetrics(
            period: period,
            referenceDate: referenceDate,
            interval: interval,
            habits: habits,
            completionMap: completionMap,
            fallback: metrics,
            isCurrent: isCurrentPeriod
        )
        let previousInterval = period.previousInterval(from: referenceDate, calendar: calendar)
        let previousMetrics = buildMetrics(interval: previousInterval, habits: habits, completionMap: completionMap)
        let monthExtremes = period == .yearly ? monthExtremes(from: highlightMetrics.dayStats) : (nil, nil)
        let streakMetrics = isCurrentPeriod ? highlightMetrics : metrics
        let finalHabitStats = mergeHabitStreaks(base: metrics.habitStats, streakSource: streakMetrics.habitStats)

        let comparison = makeComparison(current: metrics, previous: previousMetrics)
        let highlights = highlightBuilder.highlights(
            period: period,
            isCurrent: isCurrentPeriod,
            completed: highlightMetrics.completedTotal,
            expected: highlightMetrics.expectedTotal,
            completionRate: highlightMetrics.completionRate,
            bestWeekday: highlightMetrics.bestWeekday,
            topHabit: highlightMetrics.topHabitName,
            bestMonthName: monthExtremes.0,
            worstMonthName: monthExtremes.1
        )
        let annualTopStreaks = period == .yearly
            ? topYearlyStreaks(
                interval: interval,
                referenceDate: referenceDate,
                habits: habits,
                completionMap: completionMap,
                isCurrentPeriod: isCurrentPeriod
            )
            : []

        return StatsRecap(
            period: period,
            interval: interval,
            completedTotal: metrics.completedTotal,
            expectedTotal: metrics.expectedTotal,
            completionRate: metrics.completionRate,
            activeHabitsCount: metrics.activeHabitsCount,
            habitsWithCompletionCount: metrics.habitsWithCompletionCount,
            habitsNeverCompletedCount: metrics.habitsNeverCompletedCount,
            dayStats: metrics.dayStats,
            habitStats: finalHabitStats,
            dayHabitStatuses: metrics.dayHabitStatuses,
            bestWeekday: metrics.bestWeekday,
            worstWeekday: metrics.worstWeekday,
            bestMonthName: monthExtremes.0,
            worstMonthName: monthExtremes.1,
            currentStreak: streakMetrics.currentStreak,
            bestStreak: streakMetrics.bestStreak,
            comparison: comparison,
            annualTopStreaks: annualTopStreaks,
            highlights: highlights,
            primaryHighlight: highlights.first ?? "Sin datos aplicables para este periodo"
        )
    }

    private func highlightMetrics(
        period: StatsPeriod,
        referenceDate: Date,
        interval: DateInterval,
        habits: [StatsHabitSnapshot],
        completionMap: [UUID: [Date: Int]],
        fallback: StatsMetrics,
        isCurrent: Bool
    ) -> StatsMetrics {
        guard isCurrent else { return fallback }
        let endOfReference = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: referenceDate)
        ) ?? interval.end
        let highlightEnd = min(endOfReference, interval.end)
        let highlightInterval = DateInterval(start: interval.start, end: highlightEnd)
        return buildMetrics(interval: highlightInterval, habits: habits, completionMap: completionMap)
    }

    private func buildMetrics(
        interval: DateInterval,
        habits: [StatsHabitSnapshot],
        completionMap: [UUID: [Date: Int]]
    ) -> StatsMetrics {
        let startDay = calendar.startOfDay(for: interval.start)
        let endDay = calendar.startOfDay(for: interval.end)
        let activeHabits = habits.filter { habit in
            let habitStart = calendar.startOfDay(for: habit.createdAt)
            let archivedDay = habit.archivedAt.map { calendar.startOfDay(for: $0) }
            let isActiveInRange = habitStart < endDay && (archivedDay == nil || archivedDay! >= startDay)
            return isActiveInRange
        }

        var dayStats: [StatsDayStat] = []
        var dayHabitStatuses: [Date: [StatsHabitDayStatus]] = [:]
        var habitExpected: [UUID: Int] = [:]
        var habitCompleted: [UUID: Int] = [:]
        var habitDayStats: [UUID: [StatsDayStat]] = [:]
        var weekdayTotals: [Int: (completed: Int, expected: Int)] = [:]

        var day = startDay
        while day < endDay {
            var dayExpected = 0
            var dayCompleted = 0
            var statuses: [StatsHabitDayStatus] = []

            for habit in activeHabits {
                let expected = expectedCount(for: habit, on: day)
                let completed = min(1, completionMap[habit.id]?[day] ?? 0)
                if expected > 0 {
                    dayExpected += expected
                    habitExpected[habit.id, default: 0] += expected
                    statuses.append(StatsHabitDayStatus(
                        habitId: habit.id,
                        name: habit.name,
                        completed: completed,
                        expected: expected
                    ))
                    habitDayStats[habit.id, default: []].append(
                        StatsDayStat(date: day, completed: completed, expected: expected)
                    )
                }
                if completed > 0 {
                    dayCompleted += completed
                    habitCompleted[habit.id, default: 0] += completed
                }
            }

            if !statuses.isEmpty {
                dayHabitStatuses[day] = statuses
            }

            dayStats.append(StatsDayStat(date: day, completed: dayCompleted, expected: dayExpected))

            let weekday = calendar.component(.weekday, from: day)
            let totals = weekdayTotals[weekday] ?? (0, 0)
            weekdayTotals[weekday] = (totals.completed + dayCompleted, totals.expected + dayExpected)

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }

        for habit in activeHabits where habitExpected[habit.id] == nil {
            habitExpected[habit.id] = 0
            habitCompleted[habit.id] = 0
        }
        for habit in activeHabits where habitDayStats[habit.id] == nil {
            habitDayStats[habit.id] = []
        }

        let completedTotal = habitCompleted.values.reduce(0, +)
        let expectedTotal = habitExpected.values.reduce(0, +)
        let completionRate: Double? = expectedTotal > 0 ? Double(completedTotal) / Double(expectedTotal) : nil

        let habitStreaks = habitDayStats.mapValues { calculateStreaks(from: $0) }
        let habitStats = buildHabitStats(
            habits: activeHabits,
            expected: habitExpected,
            completed: habitCompleted,
            streaks: habitStreaks
        )

        let habitsWithCompletion = habitStats.filter { $0.completed > 0 }.count
        let habitsNeverCompleted = habitStats.filter { $0.expected > 0 && $0.completed == 0 }.count

        let bestWeekday = weekdayLabel(from: weekdayTotals, isBest: true)
        let worstWeekday = weekdayLabel(from: weekdayTotals, isBest: false)
        let streaks = calculateStreaks(from: dayStats)

        return StatsMetrics(
            completedTotal: completedTotal,
            expectedTotal: expectedTotal,
            completionRate: completionRate,
            activeHabitsCount: activeHabits.count,
            habitsWithCompletionCount: habitsWithCompletion,
            habitsNeverCompletedCount: habitsNeverCompleted,
            dayStats: dayStats,
            habitStats: habitStats,
            dayHabitStatuses: dayHabitStatuses,
            bestWeekday: bestWeekday,
            worstWeekday: worstWeekday,
            currentStreak: streaks.current,
            bestStreak: streaks.best,
            topHabitName: habitStats.first(where: { $0.badge == .top })?.name
        )
    }

    private func expectedCount(for habit: StatsHabitSnapshot, on date: Date) -> Int {
        let habitStart = calendar.startOfDay(for: habit.createdAt)
        if let archivedAt = habit.archivedAt {
            let archivedDay = calendar.startOfDay(for: archivedAt)
            if date > archivedDay {
                return 0
            }
        }
        if date < habitStart {
            return 0
        }
        switch habit.frequency {
        case .daily:
            return 1
        case .weekly:
            let dateWeekday = calendar.component(.weekday, from: date)
            return habit.weeklyDays.contains(dateWeekday) ? 1 : 0
        }
    }

    private func buildHabitStats(
        habits: [StatsHabitSnapshot],
        expected: [UUID: Int],
        completed: [UUID: Int],
        streaks: [UUID: (current: Int, best: Int)]
    ) -> [StatsHabitStat] {
        let baseStats: [StatsHabitStat] = habits.map { habit in
            let expectedValue = expected[habit.id] ?? 0
            let completedValue = completed[habit.id] ?? 0
            let rate: Double? = expectedValue > 0 ? Double(completedValue) / Double(expectedValue) : nil
            let habitStreak = streaks[habit.id] ?? (0, 0)
            return StatsHabitStat(
                habitId: habit.id,
                name: habit.name,
                isArchived: habit.archivedAt != nil,
                completed: completedValue,
                expected: expectedValue,
                rate: rate,
                badge: nil,
                currentStreak: habitStreak.current,
                bestStreak: habitStreak.best
            )
        }

        let topCompleted = baseStats.max { $0.completed < $1.completed }
        let mostAbandoned = baseStats
            .filter { $0.rate != nil }
            .min { lhs, rhs in
                let lhsRate = lhs.rate ?? 0
                let rhsRate = rhs.rate ?? 0
                if lhsRate == rhsRate {
                    return lhs.expected > rhs.expected
                }
                return lhsRate < rhsRate
            }

        return baseStats.map { stat in
            var badge: StatsHabitBadge?
            if let top = topCompleted, stat.habitId == top.habitId, top.completed > 0 {
                badge = .top
            } else if let abandoned = mostAbandoned, stat.habitId == abandoned.habitId, (abandoned.rate ?? 1) < 0.5 {
                badge = .risk
            }
            return StatsHabitStat(
                habitId: stat.habitId,
                name: stat.name,
                isArchived: stat.isArchived,
                completed: stat.completed,
                expected: stat.expected,
                rate: stat.rate,
                badge: badge,
                currentStreak: stat.currentStreak,
                bestStreak: stat.bestStreak
            )
        }
        .sorted { $0.completed > $1.completed }
    }

    private func weekdayLabel(from totals: [Int: (completed: Int, expected: Int)], isBest: Bool) -> String? {
        let candidates = totals.filter { $0.value.expected > 0 }
        guard !candidates.isEmpty else { return nil }

        let sorted = candidates.sorted { lhs, rhs in
            let lhsRate = Double(lhs.value.completed) / Double(lhs.value.expected)
            let rhsRate = Double(rhs.value.completed) / Double(rhs.value.expected)
            return isBest ? lhsRate > rhsRate : lhsRate < rhsRate
        }

        let weekdayIndex = sorted.first?.key ?? 1
        let symbols = calendar.weekdaySymbols
        if weekdayIndex > 0, weekdayIndex <= symbols.count {
            return symbols[weekdayIndex - 1]
        }
        return nil
    }

    private func calculateStreaks(from dayStats: [StatsDayStat]) -> (current: Int, best: Int) {
        guard !dayStats.isEmpty else { return (0, 0) }
        let sorted = dayStats.sorted { $0.date < $1.date }

        var best = 0
        var current = 0
        for day in sorted {
            if day.expected == 0 {
                continue
            }
            if day.completed == day.expected {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        var tailStreak = 0
        for day in sorted.reversed() {
            if day.expected == 0 {
                continue
            }
            if day.completed == day.expected {
                tailStreak += 1
            } else {
                break
            }
        }

        return (tailStreak, best)
    }

    private func makeComparison(current: StatsMetrics, previous: StatsMetrics) -> StatsComparison? {
        guard let currentRate = current.completionRate,
              let previousRate = previous.completionRate,
              previous.expectedTotal > 0 else {
            return nil
        }

        let deltaRate = currentRate - previousRate
        let deltaCompleted = current.completedTotal - previous.completedTotal
        let trendLabel: String
        if deltaRate >= 0.05 {
            trendLabel = "Mejorando"
        } else if deltaRate <= -0.05 {
            trendLabel = "Empeorando"
        } else {
            trendLabel = "Estable"
        }

        return StatsComparison(
            previousRate: previousRate,
            deltaRate: deltaRate,
            deltaCompleted: deltaCompleted,
            trendLabel: trendLabel
        )
    }

    private func mergeHabitStreaks(
        base: [StatsHabitStat],
        streakSource: [StatsHabitStat]
    ) -> [StatsHabitStat] {
        let streakMap = Dictionary(uniqueKeysWithValues: streakSource.map { ($0.habitId, ($0.currentStreak, $0.bestStreak)) })
        return base.map { stat in
            guard let streak = streakMap[stat.habitId] else { return stat }
            return StatsHabitStat(
                habitId: stat.habitId,
                name: stat.name,
                isArchived: stat.isArchived,
                completed: stat.completed,
                expected: stat.expected,
                rate: stat.rate,
                badge: stat.badge,
                currentStreak: streak.0,
                bestStreak: streak.1
            )
        }
    }

    func habitStreak(
        for habit: StatsHabitSnapshot,
        completionMap: [UUID: [Date: Int]],
        through referenceDate: Date
    ) -> (current: Int, best: Int) {
        let startDay = calendar.startOfDay(for: habit.createdAt)
        let endDay = calendar.startOfDay(for: referenceDate)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        let interval = DateInterval(start: startDay, end: endExclusive)
        let stats = scheduledDayStats(for: habit, interval: interval, completionMap: completionMap)
        return calculateStreaks(from: stats)
    }

    private func topYearlyStreaks(
        interval: DateInterval,
        referenceDate: Date,
        habits: [StatsHabitSnapshot],
        completionMap: [UUID: [Date: Int]],
        isCurrentPeriod: Bool
    ) -> [StatsStreakSummary] {
        let yearStart = calendar.startOfDay(for: interval.start)
        let yearEnd = calendar.startOfDay(for: interval.end)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let rangeEnd = isCurrentPeriod
            ? min(calendar.date(byAdding: .day, value: 1, to: referenceDay) ?? yearEnd, yearEnd)
            : yearEnd

        var summaries: [StatsStreakSummary] = []
        for habit in habits {
            let historyStart = calendar.startOfDay(for: habit.createdAt)
            let historyInterval = DateInterval(start: historyStart, end: rangeEnd)
            let scheduledStats = scheduledDayStats(for: habit, interval: historyInterval, completionMap: completionMap)
            let segments = streakSegments(from: scheduledStats, rangeEnd: rangeEnd)
            for segment in segments where segment.endDate >= yearStart && segment.startDate < yearEnd {
                summaries.append(StatsStreakSummary(
                    habitId: habit.id,
                    habitName: habit.name,
                    startDate: segment.startDate,
                    endDate: segment.endDate,
                    lengthDays: segment.lengthDays,
                    isActive: isCurrentPeriod ? segment.isActive : false
                ))
            }
        }

        return summaries
            .sorted {
                if $0.lengthDays == $1.lengthDays {
                    return $0.endDate > $1.endDate
                }
                return $0.lengthDays > $1.lengthDays
            }
            .prefix(3)
            .map { $0 }
    }

    private func scheduledDayStats(
        for habit: StatsHabitSnapshot,
        interval: DateInterval,
        completionMap: [UUID: [Date: Int]]
    ) -> [StatsDayStat] {
        guard interval.start < interval.end else { return [] }
        var stats: [StatsDayStat] = []
        var day = calendar.startOfDay(for: interval.start)
        let endDay = calendar.startOfDay(for: interval.end)
        while day < endDay {
            let expected = expectedCount(for: habit, on: day)
            if expected > 0 {
                let completed = min(1, completionMap[habit.id]?[day] ?? 0)
                stats.append(StatsDayStat(date: day, completed: completed, expected: expected))
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        return stats
    }

    private func streakSegments(from stats: [StatsDayStat], rangeEnd: Date) -> [StreakSegment] {
        guard !stats.isEmpty else { return [] }
        let sorted = stats.sorted { $0.date < $1.date }
        var segments: [StreakSegment] = []
        var currentStart: Date?
        var currentEnd: Date?

        for stat in sorted {
            if stat.completed >= stat.expected, stat.expected > 0 {
                if currentStart == nil {
                    currentStart = stat.date
                }
                currentEnd = stat.date
            } else {
                if let start = currentStart, let end = currentEnd {
                    segments.append(makeSegment(start: start, end: end, isActive: false))
                }
                currentStart = nil
                currentEnd = nil
            }
        }

        if let start = currentStart, let end = currentEnd {
            let lastDay = sorted.last?.date
            let isActive = lastDay != nil && calendar.isDate(end, inSameDayAs: lastDay ?? end)
                && end < rangeEnd
            segments.append(makeSegment(start: start, end: end, isActive: isActive))
        }

        return segments
    }

    private func makeSegment(start: Date, end: Date, isActive: Bool) -> StreakSegment {
        let days = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        return StreakSegment(startDate: start, endDate: end, lengthDays: max(days, 1), isActive: isActive)
    }

    private func monthExtremes(from dayStats: [StatsDayStat]) -> (String?, String?) {
        var monthlyTotals: [Int: (completed: Int, expected: Int)] = [:]
        for stat in dayStats {
            let month = calendar.component(.month, from: stat.date)
            let current = monthlyTotals[month] ?? (0, 0)
            monthlyTotals[month] = (current.completed + stat.completed, current.expected + stat.expected)
        }

        let candidates = monthlyTotals.filter { $0.value.expected > 0 }
        guard !candidates.isEmpty else { return (nil, nil) }

        let best = candidates.max { lhs, rhs in
            let lhsRate = Double(lhs.value.completed) / Double(lhs.value.expected)
            let rhsRate = Double(rhs.value.completed) / Double(rhs.value.expected)
            return lhsRate < rhsRate
        }

        let worst = candidates.min { lhs, rhs in
            let lhsRate = Double(lhs.value.completed) / Double(lhs.value.expected)
            let rhsRate = Double(rhs.value.completed) / Double(rhs.value.expected)
            return lhsRate < rhsRate
        }

        let monthSymbols = calendar.monthSymbols
        let bestName = best.flatMap { monthSymbols[safe: $0.key - 1] }
        let worstName = worst.flatMap { monthSymbols[safe: $0.key - 1] }

        if best?.key == worst?.key {
            return (bestName, nil)
        }
        return (bestName, worstName)
    }
}

private extension Array where Element == String {
    subscript(safe index: Int) -> String? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private struct StreakSegment {
    let startDate: Date
    let endDate: Date
    let lengthDays: Int
    let isActive: Bool
}

private struct StatsMetrics {
    let completedTotal: Int
    let expectedTotal: Int
    let completionRate: Double?
    let activeHabitsCount: Int
    let habitsWithCompletionCount: Int
    let habitsNeverCompletedCount: Int
    let dayStats: [StatsDayStat]
    let habitStats: [StatsHabitStat]
    let dayHabitStatuses: [Date: [StatsHabitDayStatus]]
    let bestWeekday: String?
    let worstWeekday: String?
    let currentStreak: Int
    let bestStreak: Int
    let topHabitName: String?
}

#endif
