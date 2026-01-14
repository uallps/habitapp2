#if PREMIUM || PLUGIN_CATEGORIES
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
    var category: String

    var categoryValue: HabitCategory {
        get { HabitCategory.from(rawValue: category) }
        set { category = newValue.rawValue }
    }

    init(habitId: UUID, category: HabitCategory = .wellness) {
        self.id = UUID()
        self.habitId = habitId
        self.category = category.rawValue
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        category = try container.decode(String.self, forKey: .category)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encode(category, forKey: .category)
    }
}

/// Categorías predefinidas para clasificar hábitos.
/// Cada categoría tiene un nombre localizado, un icono SF Symbol, un color distintivo
/// y una descripción que ayuda al usuario a entender qué tipo de hábitos incluir.
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

    /// Convierte un string (rawValue o nombre en inglés) a HabitCategory
    static func from(rawValue: String) -> HabitCategory {
        switch rawValue {
        case Self.wellness.rawValue, "wellness":
            return .wellness
        case Self.health.rawValue, "health":
            return .health
        case Self.learning.rawValue, "learning":
            return .learning
        case Self.productivity.rawValue, "productivity":
            return .productivity
        case Self.other.rawValue, "other":
            return .other
        default:
            return .other
        }
    }

    /// Icono SF Symbol representativo de la categoría
    var icon: String {
        switch self {
        case .wellness: return "sparkles"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .productivity: return "bolt.fill"
        case .other: return "square.grid.2x2"
        }
    }

    /// Color distintivo de la categoría
    var color: Color {
        switch self {
        case .wellness: return .purple
        case .health: return .red
        case .learning: return .blue
        case .productivity: return .orange
        case .other: return .gray
        }
    }

    /// Descripción breve de qué tipo de hábitos pertenecen a esta categoría
    var description: String {
        switch self {
        case .wellness:
            return "Meditación, mindfulness, autocuidado"
        case .health:
            return "Ejercicio, alimentación, sueño"
        case .learning:
            return "Lectura, cursos, idiomas"
        case .productivity:
            return "Organización, trabajo, metas"
        case .other:
            return "Hábitos diversos"
        }
    }

    /// Ejemplos de hábitos comunes en esta categoría
    var examples: [String] {
        switch self {
        case .wellness:
            return ["Meditar 10 min", "Escribir diario", "Agradecer"]
        case .health:
            return ["Hacer ejercicio", "Beber 2L agua", "Dormir 8h"]
        case .learning:
            return ["Leer 30 min", "Practicar inglés", "Ver tutorial"]
        case .productivity:
            return ["Planificar día", "Revisar tareas", "Inbox zero"]
        case .other:
            return ["Llamar familia", "Regar plantas", "Pasear mascota"]
        }
    }

    /// Label de accesibilidad para VoiceOver
    var accessibilityLabel: String {
        "\(rawValue): \(description)"
    }
}
#endif

