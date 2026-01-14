import Foundation
import SwiftData

@Model
final class HabitCategoryAssignment: Identifiable, Codable {
    private enum CodingKeys: CodingKey { case id, habitId, category }

    private(set) var id: UUID
    var habitId: UUID
    var category: HabitCategory

    init(habitId: UUID, category: HabitCategory = .wellness) {
        self.id = UUID()
        self.habitId = habitId
        self.category = category
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        category = try container.decode(HabitCategory.self, forKey: .category)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encode(category, forKey: .category)
    }
}

enum HabitCategory: String, CaseIterable, Identifiable, Codable {
    case wellness = "Bienestar"
    case health = "Salud"
    case learning = "Aprendizaje"
    case productivity = "Productividad"
    case other = "Otro"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wellness: return "sparkles"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .productivity: return "bolt.fill"
        case .other: return "square.grid.2x2"
        }
    }
}

