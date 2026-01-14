import Foundation
import SwiftData

@Model
final class HabitNote: Identifiable, Codable {
    private enum CodingKeys: CodingKey { case id, habitId, date, text, dayIdentifier, mood }

    private(set) var id: UUID
    var habitId: UUID
    var date: Date
    var text: String
    var dayIdentifier: String
    var mood: Int

    init(habitId: UUID, date: Date = Date(), text: String = "", mood: Int = 3) {
        self.id = UUID()
        self.habitId = habitId
        self.date = date
        self.text = text
        self.dayIdentifier = HabitNote.formatter.string(from: date)
        self.mood = mood
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

    var moodLabel: String { Self.label(for: mood) }

    static func label(for mood: Int) -> String {
        switch mood {
        case 1:
            return "😞 Muy bajo"
        case 2:
            return "😕 Bajo"
        case 3:
            return "😐 Medio"
        case 4:
            return "🙂 Bien"
        case 5:
            return "😄 Genial"
        default:
            return "😐 Medio"
        }
    }

    static func emoji(for mood: Int) -> String {
        switch mood {
        case 1:
            return "😞"
        case 2:
            return "😕"
        case 3:
            return "😐"
        case 4:
            return "🙂"
        case 5:
            return "😄"
        default:
            return "😐"
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        date = try container.decode(Date.self, forKey: .date)
        text = try container.decode(String.self, forKey: .text)
        dayIdentifier = try container.decode(String.self, forKey: .dayIdentifier)
        mood = try container.decodeIfPresent(Int.self, forKey: .mood) ?? 3
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encode(date, forKey: .date)
        try container.encode(text, forKey: .text)
        try container.encode(dayIdentifier, forKey: .dayIdentifier)
        try container.encode(mood, forKey: .mood)
    }
}
