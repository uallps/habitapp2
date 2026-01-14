#if PREMIUM || PLUGIN_CATEGORIES
import SwiftUI

/// Datos de progreso para una categoría
struct CategoryProgress {
    let completed: Int
    let total: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

/// Barra de filtrado horizontal por categorias.
/// Muestra chips seleccionables para filtrar habitos por categoria.
/// Opcionalmente muestra el conteo de hábitos y progreso por categoría.
struct CategoryFilterBar: View {
    @Binding var selectedCategory: HabitCategory?

    /// Conteo de hábitos por categoría (opcional)
    var categoryCounts: [HabitCategory: Int] = [:]

    /// Progreso por categoría (opcional)
    var categoryProgress: [HabitCategory: CategoryProgress] = [:]

    /// Total de hábitos para el chip "Todos"
    var totalCount: Int? {
        categoryCounts.isEmpty ? nil : categoryCounts.values.reduce(0, +)
    }

    /// Progreso global calculado
    var totalProgress: CategoryProgress? {
        guard !categoryProgress.isEmpty else { return nil }
        let completed = categoryProgress.values.reduce(0) { $0 + $1.completed }
        let total = categoryProgress.values.reduce(0) { $0 + $1.total }
        return CategoryProgress(completed: completed, total: total)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Boton "Todos"
                FilterChip(
                    title: "Todos",
                    icon: "list.bullet",
                    color: .accentColor,
                    count: totalCount,
                    progress: totalProgress,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                // Chips por categoria
                ForEach(HabitCategory.allCases) { category in
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        count: categoryCounts[category],
                        progress: categoryProgress[category],
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

/// Chip individual para el filtro con soporte para contador, progreso y accesibilidad
private struct FilterChip: View {
    let title: String
    let icon: String
    let color: Color
    var count: Int?
    var progress: CategoryProgress?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Icono con indicador de progreso circular
                ZStack {
                    Image(systemName: icon)
                        .font(.caption)

                    // Anillo de progreso si hay datos disponibles
                    if let progress = progress, progress.total > 0 {
                        Circle()
                            .trim(from: 0, to: progress.percentage)
                            .stroke(
                                isSelected ? Color.white : color,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 20, height: 20)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress.percentage)
                    }
                }
                .frame(width: 20, height: 20)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                // Mostrar contador si está disponible
                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected
                                ? Color.white.opacity(0.3)
                                : color.opacity(0.2)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .foregroundColor(isSelected ? .white : color)
            .clipShape(Capsule())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Filtro activo" : "Toca para filtrar por \(title)")
    }

    private var accessibilityText: String {
        var text = title
        if let count = count {
            text += ", \(count) hábitos"
        }
        if let progress = progress, progress.total > 0 {
            text += ", \(Int(progress.percentage * 100))% completado"
        }
        return text
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Sin contadores").font(.caption).foregroundColor(.secondary)
        CategoryFilterBar(selectedCategory: .constant(nil))

        Text("Con contadores").font(.caption).foregroundColor(.secondary)
        CategoryFilterBar(
            selectedCategory: .constant(nil),
            categoryCounts: [
                .wellness: 3,
                .health: 5,
                .learning: 2,
                .productivity: 4,
                .other: 1
            ]
        )

        Text("Con progreso").font(.caption).foregroundColor(.secondary)
        CategoryFilterBar(
            selectedCategory: .constant(nil),
            categoryCounts: [
                .wellness: 3,
                .health: 5,
                .learning: 2,
                .productivity: 4,
                .other: 1
            ],
            categoryProgress: [
                .wellness: CategoryProgress(completed: 2, total: 3),
                .health: CategoryProgress(completed: 3, total: 5),
                .learning: CategoryProgress(completed: 2, total: 2),
                .productivity: CategoryProgress(completed: 1, total: 4),
                .other: CategoryProgress(completed: 0, total: 1)
            ]
        )

        Text("Selección con progreso").font(.caption).foregroundColor(.secondary)
        CategoryFilterBar(
            selectedCategory: .constant(.health),
            categoryCounts: [
                .wellness: 3,
                .health: 5,
                .learning: 2,
                .productivity: 4,
                .other: 1
            ],
            categoryProgress: [
                .wellness: CategoryProgress(completed: 2, total: 3),
                .health: CategoryProgress(completed: 3, total: 5),
                .learning: CategoryProgress(completed: 2, total: 2),
                .productivity: CategoryProgress(completed: 1, total: 4),
                .other: CategoryProgress(completed: 0, total: 1)
            ]
        )
    }
    .padding()
}
#endif
