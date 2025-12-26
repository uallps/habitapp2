import Foundation
import SwiftData

@MainActor
protocol HabitNoteStorage {
    func allNotes() async throws -> [HabitNote]
    func delete(_ note: HabitNote) async throws
    func notes(for habitId: UUID) async throws -> [HabitNote]
    func note(for habitId: UUID, on date: Date) async throws -> HabitNote?
    func save(_ note: HabitNote) async throws
    func deleteNotes(for habitId: UUID) async throws
}

@MainActor
final class HabitNoteSwiftDataStorage: HabitNoteStorage {
    private var context: ModelContext? { SwiftDataContext.shared }

    func allNotes() async throws -> [HabitNote] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<HabitNote>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func notes(for habitId: UUID) async throws -> [HabitNote] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<HabitNote>(
            predicate: #Predicate { $0.habitId == habitId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ note: HabitNote) async throws {
        guard let context else { return }
        context.delete(note)
        try context.save()
    }

    func note(for habitId: UUID, on date: Date) async throws -> HabitNote? {
        guard let context else { return nil }
        let dayIdentifier = HabitNoteFormatter.identifier(from: date)
        let descriptor = FetchDescriptor<HabitNote>(predicate: #Predicate { note in
            note.habitId == habitId && note.dayIdentifier == dayIdentifier
        })
        return try context.fetch(descriptor).first
    }

    func save(_ note: HabitNote) async throws {
        guard let context else { return }
        if note.modelContext == nil {
            context.insert(note)
        }
        try context.save()
    }

    func deleteNotes(for habitId: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<HabitNote>(predicate: #Predicate { $0.habitId == habitId })
        let notes = try context.fetch(descriptor)
        for note in notes { context.delete(note) }
        if !notes.isEmpty {
            try context.save()
        }
    }
}

enum HabitNoteFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()

    static func identifier(from date: Date) -> String {
        formatter.string(from: date)
    }
}
