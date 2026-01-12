//
//  Habit.swift
//  HabitApp
//
//  Created by Codex on 03/12/25.
//
import Foundation
import SwiftData

@Model
final class Habit: Identifiable, Codable {
    private enum CodingKeys: CodingKey {
        case id, name, frequency, isCompletedToday, lastCompletionDate, createdAt, weeklyDays, archivedAt
    }

    private(set) var id: UUID
    var name: String
    var frequency: HabitFrequency
    var isCompletedToday: Bool
    var lastCompletionDate: Date?
    var weeklyDays: [Int]
    var archivedAt: Date?
    private(set) var createdAt: Date

    init(
        name: String,
        frequency: HabitFrequency = .daily,
        isCompletedToday: Bool = false,
        lastCompletionDate: Date? = nil,
        weeklyDays: [Int] = [],
        archivedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.frequency = frequency
        self.isCompletedToday = isCompletedToday
        self.lastCompletionDate = lastCompletionDate
        let defaultWeekday = Calendar.current.component(.weekday, from: createdAt)
        self.weeklyDays = weeklyDays.isEmpty && frequency == .weekly ? [defaultWeekday] : weeklyDays
        self.archivedAt = archivedAt
        self.createdAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.frequency = try container.decode(HabitFrequency.self, forKey: .frequency)
        self.isCompletedToday = try container.decode(Bool.self, forKey: .isCompletedToday)
        self.lastCompletionDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletionDate)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        let decodedWeeklyDays = try container.decodeIfPresent([Int].self, forKey: .weeklyDays) ?? []
        let defaultWeekday = Calendar.current.component(.weekday, from: createdAt)
        self.weeklyDays = decodedWeeklyDays.isEmpty && frequency == .weekly ? [defaultWeekday] : decodedWeeklyDays
        self.archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(isCompletedToday, forKey: .isCompletedToday)
        try container.encodeIfPresent(lastCompletionDate, forKey: .lastCompletionDate)
        try container.encode(weeklyDays, forKey: .weeklyDays)
        try container.encodeIfPresent(archivedAt, forKey: .archivedAt)
        try container.encode(createdAt, forKey: .createdAt)
    }

    var isArchived: Bool {
        archivedAt != nil
    }

    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        if frequency == .daily {
            return true
        }
        let weekday = calendar.component(.weekday, from: date)
        return weeklyDays.contains(weekday)
    }
}

enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "Diario"
    case weekly = "Semanal"

    var id: String { rawValue }

    var description: String { rawValue }
}
