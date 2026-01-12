import Foundation
import SwiftData

@Model
final class HabitStreak: Identifiable, Codable {
    private enum CodingKeys: CodingKey { case id, habitId, current, best, lastCompletion }

    private(set) var id: UUID
    var habitId: UUID
    var current: Int
    var best: Int
    var lastCompletion: Date?

    init(habitId: UUID, current: Int = 0, best: Int = 0, lastCompletion: Date? = nil) {
        self.id = UUID()
        self.habitId = habitId
        self.current = current
        self.best = max(best, current)
        self.lastCompletion = lastCompletion
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        current = try container.decode(Int.self, forKey: .current)
        best = try container.decode(Int.self, forKey: .best)
        lastCompletion = try container.decodeIfPresent(Date.self, forKey: .lastCompletion)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encode(current, forKey: .current)
        try container.encode(best, forKey: .best)
        try container.encodeIfPresent(lastCompletion, forKey: .lastCompletion)
    }
}
