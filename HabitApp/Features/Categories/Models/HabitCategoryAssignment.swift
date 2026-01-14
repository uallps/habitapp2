import Foundation
import SwiftData
import SwiftUI

/// Modelo que representa la asignación de una categoría a un hábito.
/// Cada hábito puede tener una única categoría asignada.
/// Se persiste usando SwiftData y se relaciona con Habit mediante habitId.
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

/// Categorías predefinidas para clasificar hábitos.
/// Cada categoría tiene un nombre localizado, un icono SF Symbol y un color distintivo.
enum HabitCategory: String, CaseIterable, Identifiable, Codable {
    /// Hábitos de autocuidado y bienestar personal
    case wellness = "Bienestar"
    /// Hábitos relacionados con salud física (ejercicio, alimentación)
    case health = "Salud"
    /// Hábitos de estudio y aprendizaje continuo
    case learning = "Aprendizaje"
    /// Hábitos de productividad y organización
    case productivity = "Productividad"
    /// Categoría general para hábitos sin clasificación específica
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

    var color: Color {
        switch self {
        case .wellness: return .purple
        case .health: return .red
        case .learning: return .blue
        case .productivity: return .orange
        case .other: return .gray
        }
    }
}

