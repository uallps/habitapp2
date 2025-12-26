import Foundation
import SwiftData

@Model
final class HabitNote: Identifiable, Codable {
    private enum CodingKeys: CodingKey { case id, habitId, date, text, dayIdentifier }

    private(set) var id: UUID
    var habitId: UUID
    var date: Date
    var text: String
    var dayIdentifier: String

    init(habitId: UUID, date: Date = Date(), text: String = "") {
        self.id = UUID()
        self.habitId = habitId
        self.date = date
        self.text = text
        self.dayIdentifier = HabitNote.formatter.string(from: date)
    }

    func update(date: Date) {
        self.date = date
        self.dayIdentifier = HabitNote.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        date = try container.decode(Date.self, forKey: .date)
        text = try container.decode(String.self, forKey: .text)
        dayIdentifier = try container.decode(String.self, forKey: .dayIdentifier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encode(date, forKey: .date)
        try container.encode(text, forKey: .text)
        try container.encode(dayIdentifier, forKey: .dayIdentifier)
    }
}
