#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import SwiftData
import SwiftUI

/// Modelo que representa la asignación de una categoría a un hábito.
/// Cada hábito puede tener una única categoría asignada.
/// Se persiste usando SwiftData y se relaciona con Habit mediante habitId.
/// Ahora usa categoryId para referenciar categorías personalizables.
@Model
final class HabitCategoryAssignment: Identifiable, Codable {
    private enum CodingKeys: CodingKey { case id, habitId, categoryId, legacyCategory }

    private(set) var id: UUID
    var habitId: UUID
    /// ID de la categoría personalizada asignada
    var categoryId: UUID?
    /// Campo legacy para migración de datos antiguos (nombre de categoría del enum)
    var legacyCategory: String?

    init(habitId: UUID, categoryId: UUID) {
        self.id = UUID()
        self.habitId = habitId
        self.categoryId = categoryId
        self.legacyCategory = nil
    }

    /// Inicializador para compatibilidad con datos legacy
    init(habitId: UUID, legacyCategory: HabitCategory) {
        self.id = UUID()
        self.habitId = habitId
        self.categoryId = nil
        self.legacyCategory = legacyCategory.rawValue
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        habitId = try container.decode(UUID.self, forKey: .habitId)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        legacyCategory = try container.decodeIfPresent(String.self, forKey: .legacyCategory)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(habitId, forKey: .habitId)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(legacyCategory, forKey: .legacyCategory)
    }

    /// Indica si esta asignación usa el formato legacy (enum) o el nuevo formato (categoryId)
    var isLegacy: Bool {
        categoryId == nil && legacyCategory != nil
    }

    /// Obtiene la categoría legacy si existe (para migración)
    var legacyCategoryValue: HabitCategory? {
        guard let legacy = legacyCategory else { return nil }
        return HabitCategory.from(rawValue: legacy)
    }
}

/// Categorías predefinidas para clasificar hábitos (legacy - mantenido para compatibilidad).
/// Las nuevas categorías usan el modelo Category persistente.
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

