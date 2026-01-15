//
//  Category.swift
//  HabitApp
//
//  Created by Valentin SCHERER on 04/09/2023.
//

#if PREMIUM || PLUGIN_CATEGORIES
import Foundation
import SwiftData
import SwiftUI

/// Modelo persistente que representa una categoría personalizable.
/// Las categorías pueden ser creadas, editadas y eliminadas por el usuario.
/// Cada categoría tiene un nombre, emoji/icono, color y descripción opcional.
@Model
final class Category: Identifiable, Codable {
    private enum CodingKeys: CodingKey {
        case id, name, emoji, colorHex, categoryDescription, isDefault, sortOrder, createdAt
    }

    private(set) var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var categoryDescription: String
    var isDefault: Bool
    var sortOrder: Int
    var createdAt: Date

    /// Color de SwiftUI calculado a partir del hex
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    /// Label de accesibilidad para VoiceOver
    var accessibilityLabel: String {
        "\(name): \(categoryDescription)"
    }

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        colorHex: String,
        categoryDescription: String = "",
        isDefault: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.categoryDescription = categoryDescription
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decode(String.self, forKey: .emoji)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        categoryDescription = try container.decode(String.self, forKey: .categoryDescription)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(categoryDescription, forKey: .categoryDescription)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Categorías predeterminadas

extension Category {
    /// Crea las categorías predeterminadas del sistema
    static func createDefaultCategories() -> [Category] {
        [
            Category(
                name: "Bienestar",
                emoji: "sparkles",
                colorHex: "#AF52DE",
                categoryDescription: "Meditación, mindfulness, autocuidado",
                isDefault: true,
                sortOrder: 0
            ),
            Category(
                name: "Salud",
                emoji: "heart.fill",
                colorHex: "#FF3B30",
                categoryDescription: "Ejercicio, alimentación, sueño",
                isDefault: true,
                sortOrder: 1
            ),
            Category(
                name: "Aprendizaje",
                emoji: "book.fill",
                colorHex: "#007AFF",
                categoryDescription: "Lectura, cursos, idiomas",
                isDefault: true,
                sortOrder: 2
            ),
            Category(
                name: "Productividad",
                emoji: "bolt.fill",
                colorHex: "#FF9500",
                categoryDescription: "Organización, trabajo, metas",
                isDefault: true,
                sortOrder: 3
            ),
            Category(
                name: "Otro",
                emoji: "square.grid.2x2",
                colorHex: "#8E8E93",
                categoryDescription: "Hábitos diversos",
                isDefault: true,
                sortOrder: 4
            )
        ]
    }
}

// MARK: - Color Extension para conversión Hex

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count

        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }

    func toHex() -> String {
        #if os(iOS)
        guard let components = UIColor(self).cgColor.components else { return "#808080" }
        #elseif os(macOS)
        guard let cgColor = NSColor(self).cgColor as CGColor?,
              let components = cgColor.components else { return "#808080" }
        #endif

        let r = Int(components[0] * 255)
        let g = Int((components[safe: 1] ?? 0) * 255)
        let b = Int((components[safe: 2] ?? 0) * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Colores predefinidos para selección

enum CategoryColor: String, CaseIterable, Identifiable {
    case red = "#FF3B30"
    case orange = "#FF9500"
    case yellow = "#FFCC00"
    case green = "#34C759"
    case mint = "#00C7BE"
    case teal = "#30B0C7"
    case cyan = "#32ADE6"
    case blue = "#007AFF"
    case indigo = "#5856D6"
    case purple = "#AF52DE"
    case pink = "#FF2D55"
    case brown = "#A2845E"
    case gray = "#8E8E93"

    var id: String { rawValue }

    var color: Color {
        Color(hex: rawValue) ?? .gray
    }

    var name: String {
        switch self {
        case .red: return "Rojo"
        case .orange: return "Naranja"
        case .yellow: return "Amarillo"
        case .green: return "Verde"
        case .mint: return "Menta"
        case .teal: return "Verde azulado"
        case .cyan: return "Cian"
        case .blue: return "Azul"
        case .indigo: return "Índigo"
        case .purple: return "Púrpura"
        case .pink: return "Rosa"
        case .brown: return "Marrón"
        case .gray: return "Gris"
        }
    }
}

// MARK: - Emojis predefinidos para selección (SF Symbols)

enum CategoryEmoji: String, CaseIterable, Identifiable {
    // Bienestar
    case sparkles = "sparkles"
    case star = "star.fill"
    case moon = "moon.fill"
    case sun = "sun.max.fill"
    case leaf = "leaf.fill"

    // Salud
    case heart = "heart.fill"
    case figure = "figure.walk"
    case dumbbell = "dumbbell.fill"
    case drop = "drop.fill"
    case bed = "bed.double.fill"

    // Aprendizaje
    case book = "book.fill"
    case graduationcap = "graduationcap.fill"
    case brain = "brain.head.profile"
    case lightbulb = "lightbulb.fill"
    case pencil = "pencil"

    // Productividad
    case bolt = "bolt.fill"
    case clock = "clock.fill"
    case calendar = "calendar"
    case checklist = "checklist"
    case target = "target"

    // Social
    case person = "person.fill"
    case people = "person.2.fill"
    case message = "message.fill"
    case phone = "phone.fill"
    case house = "house.fill"

    // Creatividad
    case paintbrush = "paintbrush.fill"
    case music = "music.note"
    case camera = "camera.fill"
    case gamecontroller = "gamecontroller.fill"
    case theatermasks = "theatermasks.fill"

    // Finanzas
    case dollarsign = "dollarsign.circle.fill"
    case creditcard = "creditcard.fill"
    case chart = "chart.line.uptrend.xyaxis"
    case bag = "bag.fill"
    case cart = "cart.fill"

    // Otros
    case grid = "square.grid.2x2"
    case folder = "folder.fill"
    case flag = "flag.fill"
    case bookmark = "bookmark.fill"
    case tag = "tag.fill"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .sparkles, .star, .moon, .sun, .leaf:
            return "Bienestar"
        case .heart, .figure, .dumbbell, .drop, .bed:
            return "Salud"
        case .book, .graduationcap, .brain, .lightbulb, .pencil:
            return "Aprendizaje"
        case .bolt, .clock, .calendar, .checklist, .target:
            return "Productividad"
        case .person, .people, .message, .phone, .house:
            return "Social"
        case .paintbrush, .music, .camera,.gamecontroller, .theatermasks:
            return "Creatividad"
        case .dollarsign, .creditcard, .chart, .bag, .cart:
            return "Finanzas"
        case .grid, .folder, .flag, .bookmark, .tag:
            return "Otros"
        }
    }
}
#endif

