import Foundation
import SwiftData

@Model
final class HabitReminder: Identifiable, Codable {
    private enum CodingKeys: CodingKey { case id, habitId, reminderDate }

    let id: UUID
    var habitId: UUID
    var reminderDate: Date?

    init(habitId: UUID, reminderDate: Date? = nil) {
        self.id = UUID()
        self.habitId = habitId
        self.reminderDate = reminderDate
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
    }
}
