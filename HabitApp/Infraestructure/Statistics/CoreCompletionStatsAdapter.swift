import Foundation
import SwiftData

@MainActor
final class CoreCompletionStatsAdapter: CompletionStatsDataSource {
    private let calendar: Calendar
    private var context: ModelContext? { SwiftDataContext.shared }

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func completions(in interval: DateInterval) async throws -> [StatsCompletionSnapshot] {
        guard let context else { return [] }
        let start = calendar.startOfDay(for: interval.start)
        let end = calendar.startOfDay(for: interval.end)
        let descriptor = FetchDescriptor<HabitCompletionRecord>(
            predicate: #Predicate { record in
                record.date >= start && record.date < end
            }
        )
        let records = try context.fetch(descriptor)
        return records.map { record in
            StatsCompletionSnapshot(habitId: record.habitId, date: record.date, count: record.count)
        }
    }

    func recordCompletion(habitId: UUID, date: Date) async throws {
        guard let context else { return }
        let day = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<HabitCompletionRecord>(
            predicate: #Predicate { record in
                record.habitId == habitId && record.date == day
            }
        )
        if let existing = try context.fetch(descriptor).first {
            if existing.count != 1 {
                existing.count = 1
                try context.save()
            }
        } else {
            let record = HabitCompletionRecord(habitId: habitId, date: day, count: 1)
            context.insert(record)
            try context.save()
        }
    }

    func removeCompletion(habitId: UUID, date: Date) async throws {
        guard let context else { return }
        let day = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<HabitCompletionRecord>(
            predicate: #Predicate { record in
                record.habitId == habitId && record.date == day
            }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    func deleteCompletions(for habitId: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitCompletionRecord>(
            predicate: #Predicate { record in
                record.habitId == habitId
            }
        )
        let records = try context.fetch(descriptor)
        for record in records {
            context.delete(record)
        }
        if !records.isEmpty {
            try context.save()
        }
    }
}

