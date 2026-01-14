import SwiftUI

/// Barra de filtrado horizontal por categorias.
/// Muestra chips seleccionables para filtrar habitos por categoria.
struct CategoryFilterBar: View {
    @Binding var selectedCategory: HabitCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Boton "Todos"
                FilterChip(
                    title: "Todos",
                    icon: "list.bullet",
                    color: .accentColor,
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

/// Chip individual para el filtro
private struct FilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .foregroundColor(isSelected ? .white : color)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        CategoryFilterBar(selectedCategory: .constant(nil))
        CategoryFilterBar(selectedCategory: .constant(.health))
    }
}
